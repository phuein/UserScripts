"""
    Scrapes data from TTC, calculates the value of recent listings in the search,
    and prints out filtered results to console.
"""

from twisted.internet import reactor
import scrapy
from scrapy.crawler import CrawlerRunner
from scrapy.utils.log import configure_logging
from scrapy.http.request import Request

from datetime import datetime
from time import sleep
from json import loads
from statistics import mean
from random import shuffle, uniform
from math import ceil

import ctypes
import os
import winsound
import signal


DEBUG = 0


# Let user force quit, if needed.
def ForceQuit(signum=None, frame=None, msg=''):
    DEBUG and msg and print(f'\n\n{GetTimestamp()} - Forced quitting: {msg}\n')

    if not OPTIONS['TRIED_QUITTING']:
        reactor.stop()
        OPTIONS['TRIED_QUITTING'] = True
    else:
        os._exit(1)  # Kill it!


OPTIONS = {
    # System settings. #
    'TRIED_QUITTING': False,    # Track CTRL-C. Twice forces quitting.
    'PRINTOUT': False,          # Track whether any items were printed since last crawl.
    # Track total listings printed out.
    'LISTING_COUNTER': 0,
    # Track total listing printed out, including skipped items.
    'TOTAL_LISTING_COUNTER': 0,
    # Track total skipped listings.
    'TOTAL_SKIPPED': 0,
    # -------------------------------------------------------------------------------- #

    # NOTE The two highest will give a notification when matched.
    'SALES': {
        0:      'NOPE',
        5000:   'SALE',
        10000:  'GOOD SALE',
        20000:  'SPICY SALE',
        30000:  'HOT SALE',
        50000:  'FLAMING SALE',
    },

    # Hash table.
    'ITEM_TRAITS': {
        None: '',
        'powered': 0,
        'charged': 1,
        'precise': 2,
        'infused': 3,
        'defending': 4,
        'training': 5,
        'sharpened': 6,
        'decisive': 7,
        'sturdy': 8,
        'impenetrable': 9,
        'reinforced': 10,
        'well fitted': 11,
        'invigorating': 12,
        'divines': 13,
        'nirnhoned': 14,
        'intricate': 15,
        'ornate': 16,
        'arcane': 17,
        'healthy': 18,
        'robust': 19,
        'special': 20,
        'bloodthirsty': 21,
        'harmony': 22,
        'protective': 23,
        'swift': 24,
        'triune': 25,
    },

    # Hash table.
    'ITEM_QUALITIES': {
        None: '',
        'any quality': '',
        'normal': 0,
        'fine': 1,
        'superior': 2,
        'epic': 3,
        'legendary': 4,
    },

    # The BUY is too expensive for the potential PROFIT.
    # Spending 100k to sell at 105k is too much investment for a 5k profit.
    # RISK_REWARD_RATIO = 2 means that the purchase cost isn't more than double the profit estimate.
    # Profit * Ratio >= Price
    # 0 to disable.
    'RISK_REWARD_RATIO': 3,

    # Nearest SALES[] value below which a listing is not displayed to the user.
    # 0 to disable.
    'IGNORE_SALES_UNDER': 5000,

    # Limit the listing purchase price.
    # If you only have 20k to spend, then no sense in listing anything over that.
    # 0 to disable.
    'IGNORE_BUYS_OVER': 0,

    # Ignore sales older than this, in minutes.
    # 0 to disable.
    # NOTE Only applies to ITEMS list crawling.
    'IGNORE_SALES_OLDER': 60,

    # How long to wait between refreshes of the spider from the start.
    'SPIDER_REFRESH_WAIT': 60 * 5,

    # How long to wait between each request for item data.
    'ITEM_WAIT': 1,

    # How long to wait before calling the connection bad.
    'CONNECTION_TIMEOUT': 10,

    # Connection retries. Proxies can have a bunch, it's normal.
    'CONNECTION_RETRIES': 2,

    # How many pages of recently listed items to crawl through.
    'URLS_PAGES': 3,

    # How many pages of each item listings to crawl through.
    'ITEM_PAGES': 3,

    # Excluded keywords in search.
    'EXCLUDE_KEYWORDS': [],

    # Required keywords in search.
    'REQUIRED_KEYWORDS': [],

    # How many units of an item must be for sale in a listing.
    'MINIMUM_UNITS': None,

    # Must not have more than this amount of units in a listing. (Game maximum stack is 200.)
    'MAXIMUM_UNITS': None,
}

# Load proxies from file.
PROXY_COUNTER = 0
PROXIES_FILE = 'proxies.txt'
PROXIES = None
try:
    with open(PROXIES_FILE) as f:
        # Not empty. Starts as a URL.
        PROXIES = [line.strip() for line in f if line.strip().startswith('http')]
    assert PROXIES  # Not empty.
    # Shuffle for when script is restarted often.
    shuffle(PROXIES)
    # Proxies are pop()ed, so reload the list from a copy.
    PROXIES_COPY = PROXIES.copy()
except Exception:
    print(f'\nFailed to load proxies from local file "{PROXIES_FILE}". Quitting...')
    os.system('pause')
    os._exit(1)


# Load items to search for from file.
ITEMS_FILE = 'items.txt'
ITEMS = None
try:
    with open(ITEMS_FILE) as f:
        # Not empty. Starts as a URL.
        ITEMS = [line.strip() for line in f if line.strip().startswith('http')]
    assert ITEMS  # Not empty.
except Exception:
    pass


def MakeBeep():
    """ Make a reasonably nice beep. Used for good sales. """
    winsound.Beep(200, 300)  # Frequency in Hertz. Duration in ms.


def FlashTaskbar():
    """ Flash the taskbar. Used for great sales. """
    ctypes.windll.user32.FlashWindow(ctypes.windll.kernel32.GetConsoleWindow(), True)


def GetTimestamp():
    """ Return a formatted timestamp. """
    return str(datetime.now().strftime('%H:%M:%S'))


# Handle both success and failure callbacks from the spider.
def sleeper(error=None):
    # Print out errors.
    error and print(f'\n\nSpider error: {str(error)}\n')

    # Sleep, but allow interruption.
    counter = 0
    while counter <= OPTIONS['SPIDER_REFRESH_WAIT'] and not OPTIONS['TRIED_QUITTING']:
        print(f'Finished a scrape, waiting {OPTIONS["SPIDER_REFRESH_WAIT"] - counter} seconds for refresh...', end='\r', flush=True)
        sleep(1)
        counter += 1

    OPTIONS['PRINTOUT'] = False


def crawl(runner):
    """ Loop with a delay. """
    d = runner.crawl(Spider)
    d.addBoth(sleeper)
    d.addBoth(lambda _: crawl(runner))
    return d


# Ask the user for input about bot options.
def GetOptions():
    global ITEMS

    # Override crawler for item list mode.
    if ITEMS:
        answer = input(
            '\n' +
            f'Items list detected! Would you like to scan only for the listed {len(ITEMS)} items [y]: '
        )
        # Let user ignore the item list.
        if answer and answer != 'y':
            ITEMS = None

    if not ITEMS:
        # Deal evaluation options:
        opts = {
            'RISK_REWARD_RATIO':
                '\n' +
                '(A value of 2 means the expected profit is at least half the buy price.)' +
                '\n' +
                'Risk ratio of BUY/PROFIT [3]: ',

            'IGNORE_SALES_UNDER':
                '\n' +
                '(Profit values closer to 0, than they are closer to this value, will not be listed.)' +
                '\n' +
                'Ignore sales under [5000]: ',
        }

        for k, v in opts.items():
            input_value = input(v)

            try:
                input_value_check = int(float(input_value))
                OPTIONS[k] = input_value_check
            except Exception:
                pass

        # Listing options:
        opts = {
            'IGNORE_BUYS_OVER':
                '\n' +
                '(Skip listings that cost more than this amount to buy.)' +
                '\n' +
                'Ignore buys over [0]: ',

            'MINIMUM_UNITS':
                '\n' +
                'Minimum amount of units [1]: ',

            'MAXIMUM_UNITS':
                '\n' +
                'Maximum amount of units [200]: ',
        }

        for k, v in opts.items():
            input_value = input(v)

            try:
                input_value_check = int(float(input_value))
                OPTIONS[k] = input_value_check
            except Exception:
                pass

        input_value = input(
            '\n' +
            '(Includes partial matches. Example: style, vanus)' +
            '\n' +
            'Exclude keywords: '
        )
        try:
            input_value_check = [
                x.strip().lower()
                for x in input_value.split(',')
                if x.strip() != ''
            ]
            OPTIONS['EXCLUDE_KEYWORDS'] = input_value_check
        except Exception:
            pass

        input_value = input(
            '\n' +
            '(Includes partial matches. Example: dagger, plati)' +
            '\n' +
            'Require keywords: '
        )
        try:
            input_value_check = [
                x.strip().lower()
                for x in input_value.split(',')
                if x.strip() != ''
            ]
            OPTIONS['REQUIRED_KEYWORDS'] = input_value_check
        except Exception:
            pass
    else:
        # Listing options.
        opts = {
            'IGNORE_SALES_OLDER':
                '\n' +
                '(Skip listings that are older than this many minutes.)' +
                '\n' +
                'Ignore older than [60]: ',
        }

        for k, v in opts.items():
            input_value = input(v)

            try:
                input_value_check = int(float(input_value))
                OPTIONS[k] = input_value_check
            except Exception:
                pass

    # Scanning options.
    opts = {
        'SPIDER_REFRESH_WAIT':
            '\n' +
            '(How long to wait after completion to start the entire crawl over, in seconds.)' +
            '\n' +
            'Spider delay [300]: ',

        # More pages puts a loads on the TTC website,
        # but less pages is less listings and more waiting.
        'URLS_PAGES':
            '\n' +
            '(More pages means more recent listings every full scan interval.)' +
            '\n' +
            'Search result pages to scan [3]: ',
    }

    for k, v in opts.items():
        input_value = input(v)

        try:
            input_value_check = int(float(input_value))
            OPTIONS[k] = input_value_check
        except Exception:
            pass


def StartCrawler():
    # Configure.
    configure_logging({'LOG_FORMAT': '\n%(levelname)s: %(message)s\n'})
    runner = CrawlerRunner()
    # Execute.
    crawl(runner)
    reactor.run()


class Item():
    """
        A TTC item with all its data.
    """

    def __init__(self, name, level, champion, quality, trait, vouchers, location, guild,
                 price_per_piece, units_count, buy_price, last_seen, ItemID=None, index=None):
        self.name               = name              # str
        self.level              = level             # 'true' or 'false'.
        self.champion           = champion
        self.quality            = quality
        self.trait              = trait             # Optional
        self.vouchers           = vouchers          # Optional, for writs.
        self.trader             = ''                # TODO 'Community' for guild trader, otherwise @player.
        self.location           = location          # '' if private sale not ignored!
        self.guild              = guild             # '' if private sale not ignored!
        self.ppp                = price_per_piece   # int
        self.units              = units_count       # int
        self.total              = buy_price         # int - Total price of listing.
        self.lastSeen           = last_seen         # int - Last seen in minutes (Seen! not listed.)
        self.values             = []                # Added later.
        self.seens              = []                # ...
        self.itemID             = ItemID
        # Tracking.
        self.value              = None              # Estimated worth.
        self.index              = index             # By order of adding.

        DEBUG and print(f'\n\n- Done parsing item: {name}\n')


class Spider(scrapy.Spider):
    """
        Crawl TTC with a new proxy for each Request(). Fetch listings from latest search results,
        and calculate their value (as resale) for print-out in console.
    """
    name = "spider"

    # Count for printing.
    counter = 0
    # Visual for printing.
    skipped = 0

    # Holds all found items.
    ITEMS = {}

    # Scrape the general search for latest listings.
    urls = [
        'https://us.tamrieltradecentre.com/pc/Trade/SearchResult?' +
        'ItemID=' +
        '&SearchType=Sell' +
        '&ItemNamePattern=' +
        '&ItemCategory1ID=' +
        '&ItemCategory2ID=' +
        '&ItemCategory3ID=' +
        '&ItemTraitID=' +
        '&ItemQualityID=' +
        '&IsChampionPoint=false' +
        '&LevelMin=' +
        '&LevelMax=' +
        '&MasterWritVoucherMin=' +
        '&MasterWritVoucherMax=' +
        '&AmountMin=' +
        '&AmountMax=' +
        '&PriceMin=' +
        '&PriceMax=' +
        '&page='
    ]

    item_autocomplete_url = 'https://us.tamrieltradecentre.com/api/pc/Trade/GetItemAutoComplete?term='

    custom_settings = {
        'DOWNLOAD_WARNSIZE': 0,
        'CONCURRENT_REQUESTS': 1,
        'CONCURRENT_ITEMS': 1,
        'LOG_LEVEL': 'ERROR',  # WARNING
        'EXTENSIONS': {
            'scrapy.extensions.logstats.LogStats': None,
        },

        'DNS_TIMEOUT': OPTIONS['CONNECTION_TIMEOUT'],
        'DOWNLOAD_TIMEOUT': OPTIONS['CONNECTION_TIMEOUT'],
        'DOWNLOAD_DELAY': OPTIONS['ITEM_WAIT'],

        'RETRY_TIMES': OPTIONS['CONNECTION_RETRIES'],
        'RETRY_HTTP_CODES': [500, 503, 504, 400, 403, 404, 408],

        'ROBOTSTXT_OBEY': 'False',

        'DOWNLOADER_MIDDLEWARES': {
            'scrapy.downloadermiddlewares.retry.RetryMiddleware': 90,
            'scrapy.downloadermiddlewares.httpproxy.HttpProxyMiddleware': 110,
            # 'scrapy.downloadermiddlewares.useragent.UserAgentMiddleware': None,
            # 'scrapy_useragents.downloadermiddlewares.useragents.UserAgentsMiddleware': 500,
        },
    }

    # TODO Move instatiated values to here! Above are shared for all instances!
    def __init__(self):
        pass

    # Track and printout item skipping.
    def SkipItem(self):
        self.skipped += 1
        OPTIONS['TOTAL_SKIPPED'] += 1

        if not OPTIONS['PRINTOUT']:
            print('\n')
            OPTIONS['PRINTOUT'] = True

        print(f'{GetTimestamp()} Skipped {self.skipped} ({OPTIONS["TOTAL_SKIPPED"]}) items...', end='\r', flush=True)

    # Estimate the value of an item from its listings.
    # Return the smart average, its digits category, and the values kept in the analysis.
    def GetAverageValue(self, values):
        # Number of digits in price. No fractions in the game.
        categories = {
            '1': 0,
            '2': 0,
            '3': 0,     # Hundreds.
            '4': 0,     # Thousands.
            '5': 0,
            '6': 0,
            '7': 0,     # Millions.
            '8': 0,
            '9': 0,
        }

        # Number of digits in the number is its category.
        for v in values:
            categories[(str(len(str(v))))] += 1

        # Get the biggest one. If more than one, get the bigger category.
        category = max(reversed(sorted(categories.keys())), key=(lambda k: categories[k]))

        # Keep only the values in the category.
        kept = []
        for v in values:
            cat = str(len(str(v)))
            if cat == category:
                # Round to category less two digit. (1,553 -> 1,600)
                r = round(v, -int(category) + 2)
                kept.append(r)

        # Add values from another category if it has a meaningful amount of listings.
        for v in values:
            cat = str(len(str(v)))
            # Skip main category.
            if cat == category:
                continue
            # NOTE Hard to say what number makes sense. Ratios don't make sense in any format.
            if categories[cat] >= 10:
                # Round to category less two digit. (1,553 -> 1,600)
                r = round(v, -int(category) + 2)
                kept.append(r)

        return mean(kept), category, kept

    # Figure out what is an expected sale price.
    # Saves and returns the resulting value calculations.
    # Sorts the Values at the end.
    # Ignored listings return None.
    def CalcItemValue(self, item):
        '''
        p = [15000, 15000, 14500, 22500, 33000, 9999, 27000, 35500, 150000, 200000]

        1. Count how many digits are in each number: Singles, Doubles, Hundreds, Thousands, Tens of, Hundreds of, Millions.
            (8 Tens of, 2 Hundreds of.)

        2. Select the most used digits state. (Tens of.) [15000, 15000, 14500, 22500, 33000, 9999, 27000, 35500]

        3. Round all up or down (by nearness to middle) to one digit under category.
            [15000, 15000, 15000, 23000, 33000, 10000, 27000, 36000]

        4. Get the mean(). (21750)

        5. Get the nearest sale prices below and over the mean. (15000, 33000)

        Return all 3 last results rounded. ("22,000 [15,000, 33,000]")
        '''

        values = item.values
        len_values = len(values)
        units = item.units
        ppp = item.ppp
        last_seens = item.seens

        # Get estimates.
        avrg, category, kept = self.GetAverageValue(values)
        # No fractions.
        avrg = int(avrg)
        # Round to category.
        avrg = round(avrg, -int(category) + 2)

        # Save estimated average price.
        item.value = avrg

        # Separate prices around the mean.
        underMean = [p for p in kept if p < avrg]
        overMean = [p for p in kept if p > avrg]

        # Get range.
        nearestUnder = underMean and min(underMean, key=lambda x: abs(x - avrg)) or 0
        nearestOver = overMean and min(overMean, key=lambda x: abs(x - avrg)) or 0
        # Round to category.
        nearestUnder = round(nearestUnder, -int(category) + 2)
        nearestOver = round(nearestOver, -int(category) + 2)

        # Find my potential profit. Stacks calculate selling the whole stack.
        # Example: 120g * 37 - 35g * 37 = 4440 - 1295 = 3,145g EARNINGS
        profit = (avrg * units) - (ppp * units)
        # Round to category.
        profit = round(profit, -int(category) + 2)

        # Find nearest sale category value.
        # Example: profit = 3,145g matches category [5000]. 1,232g would match [0].
        nearestCategory = min(list(OPTIONS['SALES']), key=lambda x: abs(x - profit))

        # Under profit threshold.
        # NOTE replace nearestCategory with profit, for accuracy?
        if OPTIONS['IGNORE_SALES_UNDER'] and nearestCategory < OPTIONS['IGNORE_SALES_UNDER']:
            DEBUG and print(f'\n\n- Skipping listing from calc nearestCategory {nearestCategory} < {OPTIONS["IGNORE_SALES_UNDER"]}: {item.name}\n')
            return

        # For the same profit, the smaller the purchase the better.
        # Example: 3,145g * 1 >=  1,295g
        if not profit:
            # All values are the same. IGNORE_SALES_UNDER normally filters this out.
            risk = 0
        else:
            risk = (ppp * units) / profit

        # print(f'\n\nRisk: {risk}')

        # The advanced cost is too high for the potential profit.
        # Example: BUY 100k, SELL 105k, PROFIT 5k. risk = 100 / 5 = 20
        # NOTE add < 0 case?
        if OPTIONS['RISK_REWARD_RATIO'] and risk > OPTIONS['RISK_REWARD_RATIO']:
            DEBUG and print(f'\n\n- Skipping listing from calc risk {risk} > {OPTIONS["RISK_REWARD_RATIO"]}: {item.name}\n')
            return

        limited_supply = False
        if len_values < 10:
            # Limited supply items don't even have 10 results in TTC.
            limited_supply = True

        # Trends. Recognize when an item is being sold a lot (more than twice an hour?)
        # and the price is dropping daily (in the last 3 days?)
        hourly_sales = 0
        prices_today = []
        prices_yesterday = []
        prices_ereyesterday = []
        i = 0  # Index.
        for m in last_seens:
            # Count sales in last hour.
            if m <= 60:
                hourly_sales += 1

            if m <= 1440:
                prices_today.append(values[i])
            elif m <= 2880:
                prices_yesterday.append(values[i])
            elif m <= 4320:
                prices_ereyesterday.append(values[i])

            i += 1

        # Figure out if there's a trend in daily pricing.
        a = b = c = 0

        if prices_today:
            a = self.GetAverageValue(prices_today)[0]
        if prices_yesterday:
            b = self.GetAverageValue(prices_yesterday)[0]
        if prices_ereyesterday:
            c = self.GetAverageValue(prices_ereyesterday)[0]

        if a > b and b > c:
            # Price is rising daily.
            trend = mean([a - b, b - c])
        elif a < b and b < c:
            # Price is dropping daily.
            trend = mean([b - a, c - b])
        else:
            # Price has no simple trend.
            trend = 0

        return avrg, nearestUnder, nearestOver, nearestCategory, profit, limited_supply, hourly_sales, trend

    # Extracts item values in TTC from a .css() selector result.
    # nameOnly - Optionally only return the name. Helps validity checks.
    # Return None on failure.
    def ExtractItem(self, item, nameOnly=None, exceptions=True):
        # Item name.
        name = item.css('td:nth-child(1) > div:nth-of-type(1)::text').get()
        # Remove whitespaces.
        name = name.strip()

        if nameOnly:
            return name

        try:
            champion = item.css('td:nth-child(1) > div:nth-of-type(3) > img::attr(src)').get()
            if champion is None:
                raise Exception()
        except Exception:
            # In third div.
            champion = item.css('td:nth-child(1) > div:nth-of-type(2) > img::attr(src)').get()

        # /Content/icons/nonvet.png or /Content/icons/championPoint.png
        if 'championPoint' in champion:
            champion = 'true'
        else:
            champion = 'false'

        try:
            level = item.css('td:nth-child(1) > div:nth-of-type(3)::text').getall()[1]
            if level is None:
                raise Exception()
        except Exception:
            # In third div.
            level = item.css('td:nth-child(1) > div:nth-of-type(2)::text').getall()[1]

        quality = item.css('td:nth-child(1) > img::attr(class)').get()
        quality = quality.strip().split()[1].split('-')[-1]

        trait = item.css('td:nth-child(1) > img::attr(data-trait)').get()

        try:
            v = item.css('td:nth-child(1) > div:nth-of-type(2)::text').get()
            vouchers = int(v.split()[1])
        except Exception:
            # Not a writ.
            vouchers = ''
            pass

        location = ''
        guild = ''
        try:
            place = item.css('td:nth-child(3) > div::text').getall()
            location = place[0]
            guild = place[1]
        except Exception:
            # Some listings are from a user, not a trader, so ignore those.
            DEBUG and print(f'\n\n- Skipping listing from user sale: {name}\n')
            if exceptions:
                return

        pricings = item.css('td:nth-child(4)::text').getall()

        price_per_piece = pricings[1]
        units_count = pricings[3]
        buy_price = pricings[5]

        last_seen = item.css('td:nth-child(5)::attr(data-mins-elapsed)').get()

        # Remove whitespaces.
        level = level.strip()
        quality = quality.strip()
        location = location.strip()
        guild = guild.strip()
        price_per_piece = price_per_piece.strip()
        units_count = units_count.strip()
        last_seen = last_seen.strip()

        # Remove commas.
        price_per_piece = price_per_piece.replace(',', '')
        units_count = units_count.replace(',', '')
        buy_price = buy_price.replace(',', '')
        last_seen = last_seen.replace(',', '')
        # Remove decimal point. Rounds down!
        price_per_piece = int(float(price_per_piece))
        units_count = int(float(units_count))
        buy_price = int(float(buy_price))
        last_seen = int(float(last_seen))

        # Lowercase for dict and url matching.
        quality = quality.lower()
        if trait is not None:
            trait = trait.lower()

        return Item(name, level, champion, quality, trait, vouchers, location, guild,
                    price_per_piece, units_count, buy_price, last_seen)

    # Yielded bad proxy. Remove it from list, and yield same request with new proxy.
    def BadProxy(self, failure=None):
        global PROXIES_COPY

        # Pass original request data for reuse: Search page, ItemID, or item search page.
        r = failure.request

        # Remove bad proxies from safe list.
        PROXIES_COPY.remove(r.meta['proxy'])

        # Copy all optional meta properties. Use new proxy.
        meta = {}

        if 'name' in r.meta:
            meta['name'] = r.meta['name']
        if 'item' in r.meta:
            meta['item'] = r.meta['item']
        if 'page' in r.meta:
            meta['page'] = r.meta['page']
        if 'index' in r.meta:
            meta['index'] = r.meta['index']
        if 'retries' in meta:
            meta['retries'] = r.meta['retries']

        meta['proxy'] = self.GetProxy()
        meta['retry'] = 'bad connection'

        # If no connection or blocked by captcha, try another proxy.
        yield Request(
            url=r.url,
            callback=r.callback,
            meta=meta,
            headers=r.headers,
            errback=self.BadProxy,
            dont_filter=True,
        )

    # Gets the current proxy and moves to the next, for next request.
    def GetProxy(self):
        global PROXY_COUNTER, PROXIES

        try:
            p = PROXIES.pop(0)  # Avoid async getting the same item.
        except Exception:
            DEBUG and print(f'\n\n- Restarting proxy list...\n')
            # Emptied the list, so reload it to start over.
            PROXIES = PROXIES_COPY.copy()
            p = PROXIES.pop(0)
            PROXY_COUNTER = 0

        # Next request will get the next proxy.
        PROXY_COUNTER += 1

        return p

    # First call.
    def start_requests(self):
        global ITEMS

        DEBUG and print(f'\n\n- Starting crawler...\n')

        if not ITEMS:
            for i in range(OPTIONS['URLS_PAGES']):
                yield Request(
                    url=f'{self.urls[0]}{i+1}',
                    callback=self.parse,
                    meta={'proxy': self.GetProxy(), 'page': i + 1},
                    errback=self.BadProxy,
                    dont_filter=True
                )
        else:
            i = 0
            for url in ITEMS:
                # Scan the item's recent listings.
                yield Request(
                    url=url,
                    callback=self.parse_get_item_value,
                    meta={'proxy': self.GetProxy(), 'page': 1, 'index': i},
                    errback=self.BadProxy,
                    dont_filter=True
                )
                # Track indexing.
                i += 1

    def parse(self, response):
        """
            Gets items from search results page.
            Sends to parse_set_item().
        """

        selector = response.css('tr.cursor-pointer')
        count = len(selector)
        noneSelector = response.xpath("//h4[contains(., 'No trade matches your constraint')]")

        # Blocked by captcha!
        if not selector and not noneSelector:
            # Call page again with new proxy.
            yield Request(
                url = response.url,
                callback = response.request.callback,
                meta = {'proxy': self.GetProxy(), 'page': response.meta['page'], 'retry': 'blocked by captcha'},
                errback=self.BadProxy,
                dont_filter=True,
            )
            return

        DEBUG and print(f'\n\n-- Started parsing TTC page #{response.meta["page"]} - {count} items.\n')

        # Get recently listed items and their data.
        for item in selector:
            name = self.ExtractItem(item, True)

            # Skip unmatched item names. TODO Abstract to function.
            try:
                for word in OPTIONS['EXCLUDE_KEYWORDS']:
                    if word in name.lower():
                        raise Exception(f'skipping {name} excluded word {word}')
                for word in OPTIONS['REQUIRED_KEYWORDS']:
                    if word not in name.lower():
                        raise Exception(f'skipping {name} required word {word}')
            except Exception as e:
                # Skip listing.
                DEBUG and print(f'\n\n- Skipping listing from name: {name}\nReason: {e}\n')
                self.SkipItem()
                continue

            # REQUIRED. Get ItemID for accurate TTC searching.
            yield Request(
                url = scrapy.utils.url.safe_url_string(self.item_autocomplete_url + name),
                callback = self.parse_set_item,
                meta = {'proxy': self.GetProxy(), 'name': name, 'item': item},
                headers={'content-type': "application/json",
                         'accept': "text/plain, */*; q=0.01"},
                errback=self.BadProxy,
                dont_filter=True,
            )

    def parse_set_item(self, response):
        """
            Gets ItemID for item.
            Sends to parse_get_value().
        """

        OPTIONS['TOTAL_LISTING_COUNTER'] += 1

        try:
            j = loads(response.body)
            ItemID = j[0]['ItemID']
        except Exception:
            print(f'\n\n- Failed to get ItemID for {response.meta["name"]}. Probably bad proxy. Dropping listing.\n')
            return

        name = response.meta['name']
        item = response.meta['item']
        proxy = response.meta['proxy']

        if DEBUG:
            if 'retry' in response.meta:
                print(f'\n\n- Parsing item (after {response.meta["retry"]}): {name}\tProxies left: {len(PROXIES)}\n')
            else:
                print(f'\n\n- Parsing item: {name}\n')

        item = self.ExtractItem(item)

        # Any failure from extraction, such as listing from player - not guild trader.
        if not item:
            self.SkipItem()
            return

        # Skip listings outside of limits. TODO Abstract to function.
        if OPTIONS['IGNORE_BUYS_OVER'] and item.total > OPTIONS['IGNORE_BUYS_OVER']:
            DEBUG and print(f'\n\n- Skipping listing buy_price {item.total} > {OPTIONS["IGNORE_BUYS_OVER"]}: {name}\n')
            self.SkipItem()
            return
        if OPTIONS['MINIMUM_UNITS'] and item.units < OPTIONS['MINIMUM_UNITS']:
            DEBUG and print(f'\n\n- Skipping listing units_count {item.units} < {OPTIONS["MINIMUM_UNITS"]}: {name}\n')
            self.SkipItem()
            return
        if OPTIONS['MAXIMUM_UNITS'] and item.units > OPTIONS['MAXIMUM_UNITS']:
            DEBUG and print(f'\n\n- Skipping listing units_count {item.units} > {OPTIONS["MAXIMUM_UNITS"]}: {name}\n')
            self.SkipItem()
            return

        # Add to collection.
        # TODO or update existing item.
        index = len(self.ITEMS) + 1
        self.ITEMS[index] = item

        # Add parse values to item.
        item.itemID = ItemID
        item.index = index

        # Get listing pages for the item, to aggregate its market value.
        # NOTE Must get to the last page of OPTIONS['ITEM_PAGES'], or no printout!
        page = 1
        yield Request(
            f'https://us.tamrieltradecentre.com/pc/Trade/SearchResult?ItemID={item.itemID}&SearchType=Sell' +
            f'&ItemNamePattern=&ItemCategory1ID=&ItemCategory2ID=&ItemCategory3ID=' +
            f'&ItemTraitID={OPTIONS["ITEM_TRAITS"][item.trait]}&ItemQualityID={OPTIONS["ITEM_QUALITIES"][item.quality]}' +
            f'&IsChampionPoint={item.champion}&LevelMin={item.level}&LevelMax={item.level}' +
            f'&MasterWritVoucherMin={item.vouchers}&MasterWritVoucherMax={item.vouchers}' +
            f'&AmountMin=&AmountMax=&PriceMin=&PriceMax=&page={page}',
            callback = self.parse_get_value,
            meta = {'proxy': proxy, 'item': item, 'page': page, 'name': name},
            errback=self.BadProxy,
            dont_filter=True,
        )

    def parse_get_value(self, response):
        """
            Gets recent listing values for item, and calculate worth of original item listing.
            TODO Merge item by ItemID, so they all share values,
                 but each has its own PPP and Location.
        """
        r = response
        meta = r.meta

        item = meta['item']
        page = meta['page']
        proxy = meta['proxy']
        name = item.name

        # Limit retries. NOTE Bug that causes unending failures? Bad proxy list?
        retries = 1
        if 'retries' in meta:
            retries = meta['retries']
        if retries > 7:
            # Skips listing. TODO Unwanted!
            DEBUG and print(f'\n\n- Dropping item page #{page} (after {meta["retry"]}) ({retries}): {name}\tProxies left: {len(PROXIES)}\n')
            self.SkipItem()
            return

        if DEBUG:
            if 'retry' in meta:
                print(f'\n\n- Parsing item page #{page} (after {meta["retry"]}) ({retries}): {name}\tProxies left: {len(PROXIES)}\n')
            else:
                print(f'\n\n- Parsing item page #{page}: {name}\n')

        selector = r.css('tr.cursor-pointer')
        noneSelector = r.xpath("//h4[contains(., 'No trade matches your constraint')]")

        # Blocked by captcha!
        if not selector and not noneSelector:
            # Call page again with new proxy.
            yield Request(
                url = r.url,
                callback = r.request.callback,
                meta = {'proxy': self.GetProxy(), 'item': item, 'page': page,
                        'name': name, 'retry': 'blocked by captcha', 'retries': retries + 1},
                errback=self.BadProxy,
                dont_filter=True,
            )
            return

        # Get all of this item's prices per piece (unit) recently listed.
        for i in r.css('tr.cursor-pointer'):
            price_per_piece = i.css('td:nth-child(4)::text').getall()[1]
            last_seen = i.css('td:nth-child(5)::attr(data-mins-elapsed)').get()

            # Remove whitespaces.
            price_per_piece = price_per_piece.strip()
            last_seen = last_seen.strip()
            # Remove decimals and points.
            price_per_piece = price_per_piece.replace(',', '')
            last_seen = last_seen.replace(',', '')
            # Remove decimal point. Rounds down!
            price_per_piece = int(float(price_per_piece))
            last_seen = int(float(last_seen))

            item.values.append(price_per_piece)
            item.seens.append(last_seen)

        DEBUG and print(f'\n\n- Finished page #{page}: {name}\n')

        # If not last page of search.
        if page < OPTIONS['ITEM_PAGES']:
            # Wait between every page, like a human would.
            sleep(uniform(10.5, 15.5))
            # Next page.
            page = page + 1
            # Callback next page.
            yield Request(
                url = f'https://us.tamrieltradecentre.com/pc/Trade/SearchResult?ItemID={item.itemID}&SearchType=Sell' +
                      f'&ItemNamePattern=&ItemCategory1ID=&ItemCategory2ID=&ItemCategory3ID=' +
                      f'&ItemTraitID={OPTIONS["ITEM_TRAITS"][item.trait]}&ItemQualityID={OPTIONS["ITEM_QUALITIES"][item.quality]}' +
                      f'&IsChampionPoint={item.champion}&LevelMin={item.level}&LevelMax={item.level}' +
                      f'&MasterWritVoucherMin={item.vouchers}&MasterWritVoucherMax={item.vouchers}' +
                      f'&AmountMin=&AmountMax=&PriceMin=&PriceMax=&page={page}',
                callback = r.request.callback,
                meta = {'proxy': proxy, 'item': item, 'page': page, 'name': name},
                errback=self.BadProxy,
                dont_filter=True,
            )
            return

        # Calculate value after last page, if there are any values.
        if item.values:
            avrg, nearestUnder, nearestOver, nearest, profit, limited_supply, hourly_sales, trend = \
                self.CalcItemValue(item) or [None for x in range(8)]

            # Item ignored in calc.
            if not avrg:
                DEBUG and print(f'\n\n- Skipping listing from calc: {name}\n')
                self.SkipItem()
                return

            # DEBUG track proxy changes
            # p = r.request.meta["proxy"]
            # msg += f'\nproxy #{PROXIES.index(p)}'

            # Values range to meaningful text.
            value_range = ''
            if nearestUnder:
                value_range = str(nearestUnder)
            if nearestOver:
                # Inbetween sign.
                if nearestUnder:
                    value_range += ' < '
                value_range += str(nearestOver)

            values_len = len(item.values)
            values = sorted(item.values)
            if values_len > 15:
                # Split into lines of 15 values max.
                v = []
                for i in range(ceil(values_len / 15)):
                    start = i * 15
                    end = (i + 1) * 15
                    v.append(str(values[start:end]))
                # Add a newline between parts.
                values = '\n'.join(v)

            # Buy price.
            buyTotal = item.total
            buyPPP = ''

            # Sell price, for same batch.
            sellTotal = avrg * item.units
            sellPPP = ''

            # Item quality.
            quality = '(' + item.quality.capitalize() + ') '

            # Optionals.
            trait = ''
            units = ''
            vouchers = ''

            if item.trait is not None:
                trait = '(' + item.trait.capitalize() + ') '

            # More than 1 unit.
            if item.units > 1:
                units = str(item.units) + ' x '
                # Print out, as well.
                buyPPP = f'({item.ppp:,}g)'
                sellPPP = f'({avrg:,}g)'

            if item.vouchers:
                vouchers = '(' + str(item.vouchers) + ' Vouchers) '

            if limited_supply:
                limited_supply = 'Limited supply!'
            else:
                limited_supply = ''

            # Attention on amazing sales! Last two values.
            if nearest >= sorted(OPTIONS['SALES'])[-2]:
                MakeBeep()
                FlashTaskbar()

            # Blueprint: High Elf Bookcase, Winged (Epic) | Deshaan: Mournhold by "Ethereal Traders Union II"
            # BUY 16,311g | SELL 28,000g [18,000g < 30,000g] | HOT SALE - EARNINGS 11689g
            # [15000, 16311, 18000, 30000, 30000, 30000, 30000, 33300] Limited supply!
            msg = (f'{units}{item.name} {quality}{trait}{vouchers}| {item.location} by "{item.guild}"\n' +
                   f'BUY {buyTotal:,}g {buyPPP}| SELL {sellTotal:,}g [{value_range}] {sellPPP}| {OPTIONS["SALES"][nearest]} | ' +
                   f'PROFIT {profit:,}g | HOURLY: {hourly_sales}\n' +  # | PRICE TREND {trend:,}g\n' +
                   f'{"-"*80}\n' +
                   f'{values} {limited_supply}')

            self.print_value(msg)

    # In tandem with ScanItems() only.
    def parse_get_item_value(self, response):
        """
            Make the Item() and find new listings (as filtered by the url.)
        """

        OPTIONS['TOTAL_LISTING_COUNTER'] += 1

        r = response
        meta = r.meta
        url = r.url

        DEBUG and print(f'url: {url}')

        page = meta['page']
        index = meta['index']
        proxy = meta['proxy']

        item = None
        if 'item' in meta:
            item = meta['item']

        newItems = []
        if 'newItems' in meta:
            newItems = meta['newItems']

        # Limit retries. NOTE Bug that causes unending failures? Bad proxy list?
        retries = 1
        if 'retries' in meta:
            retries = meta['retries']
        if retries > 7:
            # Skips listing. TODO Unwanted!
            DEBUG and print(f'\n\n- Dropping item page #{page} (after {meta["retry"]}) ({retries}): {url}\tProxies left: {len(PROXIES)}\n')
            self.SkipItem()
            return

        if DEBUG:
            if 'retry' in meta:
                print(f'\n- Parsing item page #{page} (after {meta["retry"]}) ({retries}): {url}\tProxies left: {len(PROXIES)}\n')
            else:
                print(f'\n- Parsing item page #{page}: {url}\n')

        selector = r.css('tr.cursor-pointer')
        count = len(selector)
        noneSelector = r.xpath("//h4[contains(., 'No trade matches your constraint')]")

        DEBUG and print(f'\n\n - Nothing in selector: {not selector} | Nothing in noneSelector: {not noneSelector}\n')

        # Blocked by captcha!
        if not selector and not noneSelector:
            # Call page again with new proxy.
            yield Request(
                url = url,
                callback = r.request.callback,
                meta = {'proxy': self.GetProxy(), 'item': item, 'page': page,
                        'index': index, 'retry': 'blocked by captcha', 'retries': retries + 1},
                errback=self.BadProxy,
                dont_filter=True,
            )
            return

        # No results for search url, at the time.
        if page == 1 and not selector:
            DEBUG and print(f'\nNo results for: {url}\n')
            return

        # Set up the item object from first listing.
        if not item:
            if index in self.ITEMS:
                item = self.ITEMS[index]
            else:
                item = self.ExtractItem(selector[0], exceptions=False)

                item.index = index

                # Extract ItemID from url.
                # TODO Optional get ItemID from API with link.
                try:
                    s = 'ItemID='
                    start = url.find(s)
                    assert start >= 0
                    start += len(s)
                    end = url.find('&', start)

                    ItemID = url[start:end]
                    assert ItemID and int(ItemID)
                except Exception:
                    print(f'\nItem link without ItemID! Skipping: {url}\n')
                    return

                item.itemID = ItemID
                # Reset lastSeen to start tracking.
                item.lastSeen = 0

                # Add to list.
                self.ITEMS[index] = item

        # Get all of this item's prices per piece (unit) recently listed.
        allFurtherOld = False
        for i in selector:
            o = self.ExtractItem(i)

            # Private sale.
            if not o:
                continue

            # An estimate of whether the listing is the same as an existing one.
            known = False
            for j in item.values:
                if (
                    j.location == o.location and j.guild == o.guild and
                    j.ppp == o.ppp and j.units == o.units
                ):
                    DEBUG and print(f'\nSkipping known - {j.location} == {o.location}, {j.guild} == {o.guild}, ' +
                                    f'{j.ppp} == {o.ppp}, {j.units} == {o.units}\n')
                    known = j
                    break
            if known:
                # Remove a known listing if it got too old.
                if o.lastSeen > OPTIONS['IGNORE_SALES_OLDER']:
                    DEBUG and print(f'\n - Removing {o.name} {o.lastSeen}m from item.values: ' +
                                    f'{o.lastSeen} > {OPTIONS["IGNORE_SALES_OLDER"]}.\n')
                    item.values.remove(known)
                continue

            # Ignore old listings. Further listings will not be newer!
            if o.lastSeen > OPTIONS['IGNORE_SALES_OLDER']:
                allFurtherOld = True
                break

            # Track listings to avoid repetition.
            item.values.append(o)

            # Keep between crawls, for printout.
            newItems.append(o)

        DEBUG and print(f'\n\n- Finished page #{page}: {item.name}\n')

        # Go to next page, if:
        # not last page of search,
        # and page had a full page of 10 items,
        # and further listings aren't too old.
        if page < OPTIONS['ITEM_PAGES'] and count == 10 and not allFurtherOld:
            page = page + 1

            # Update page number.
            if '&page=' not in url:
                # url might not have the page part.
                url += f'&page={page}'
            else:
                # Replace page number.
                s = 'page='
                start = url.find(s)
                start += len(s)

                url = f'{url[:start]}{page}'
            # print(f'url page #{page} -> {url}')

            # Wait between every page, like a human would.
            sleep(uniform(10.5, 15.5))

            # Callback next page.
            yield Request(
                url = url,
                callback = response.request.callback,
                meta = {'proxy': proxy, 'item': item, 'page': page,
                        'index': index, 'newItems': newItems},
                errback=self.BadProxy,
                dont_filter=True,
            )
            return

        # Print all new results.
        for newItem in newItems:
            # Buy price.
            buyTotal = newItem.total
            buyPPP = ''

            # Item quality.
            quality = '(' + newItem.quality.capitalize() + ') '

            # Optionals.
            trait = ''
            units = ''
            vouchers = ''

            if newItem.trait is not None:
                trait = '(' + newItem.trait.capitalize() + ') '

            if newItem.vouchers:
                vouchers = '(' + str(newItem.vouchers) + ' Vouchers) '

            lastSeen = newItem.lastSeen
            if lastSeen >= 60:
                # Days.
                days = int(lastSeen / 60 / 24)
                if not days:
                    days = ''
                else:
                    days = f'{days} day{(days>1 and "s") or ""}, '
                # Hours.
                hours = int(lastSeen / 60)
                if not hours:
                    hours = ''
                else:
                    hours = f'{hours} hour{(hours>1 and "s") or ""}, '
                # Minutes.
                mins = lastSeen % 60
                if not mins:
                    mins = ''
                else:
                    mins = f'{mins} minute{(mins>1 and "s") or ""}.'

                lastSeen = days + hours + mins
            else:
                lastSeen = f'{lastSeen} minutes.'

            # Attention on amazing sales! Half max value, if set.
            priceMax = 0
            if 'PriceMax=' in url:
                start = url.find('PriceMax=')
                start += len('PriceMax=')
                end = url.find('&', start)
                if end == -1:
                    end = None

                priceMax = int(url[start:end])
                if not priceMax:
                    priceMax = 0

                # print(newItem.ppp, priceMax)
                if newItem.ppp <= item.ppp / 2:
                    FlashTaskbar()

                priceMax = f'<= {priceMax:,}g '

            # More than 1 unit.
            if newItem.units > 1:
                units = str(newItem.units) + ' x '
                # Print out.
                if priceMax:
                    buyPPP = f'- {newItem.ppp:,}g '

            MakeBeep()

            # Blueprint: High Elf Bookcase, Winged (Epic) | Deshaan: Mournhold by "Ethereal Traders Union II"
            # BUY 16,311g | 7 hours, 41 minutes.
            msg = (f'{units}{newItem.name} {quality}{trait}{vouchers}| {newItem.location} by "{newItem.guild}"\n' +
                   f'BUY {buyTotal:,}g {buyPPP}{priceMax}| {lastSeen}')

            self.print_value(msg)

    def print_value(self, msg):
        """
            Print out the item's value and details.
            Optional: Ignore low value deals.
        """

        OPTIONS['LISTING_COUNTER'] += 1

        self.counter += 1  # DEBUG

        # Reset skipped counter on every print.
        self.skipped = 0

        if not OPTIONS['PRINTOUT']:
            print('\n')
            OPTIONS['PRINTOUT'] = True

        print(f'{GetTimestamp()} ({self.counter}) ({OPTIONS["LISTING_COUNTER"]}) ({OPTIONS["TOTAL_LISTING_COUNTER"]})\n{msg}\n')


# TODO:
# - Option at the end to print to html file for easy viewing.
# - After the digits group, there's which leading number is the most common.
#   e.g. [32550, 32550, 35550, 35550, 50000, 69999, 69999, 70000, 85000]
#   It's all 5 digits, but 3 is the most common leading number.

if __name__ == "__main__":
    # Catch CTRL-C.
    signal.signal(signal.SIGINT, ForceQuit)

    GetOptions()
    StartCrawler()

    # Quitting...
    print(f'\n\n{GetTimestamp()} - Quitting...\n')
    os.system('pause')
    os.system('pause')
