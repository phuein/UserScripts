"""
    Finds good deals for resale from TTC and prints them to an HTML page.

    - Uses proxies, if provided in a local file named "proxies.txt" in the format "http://123.123.123.123:123" per line.
    - Only checks a given list of items, if provided in a local file named "items.txt" in their search-results page URL format per line.
"""

import signal
import os
from traceback import format_exc

from datetime import datetime
from random import shuffle, uniform
from time import sleep
from math import ceil
from statistics import mean

from lxml import html
import requests

DEBUG = True


# Let user force quit, if needed.
def ForceQuit(signum=None, frame=None, msg='', graceful=True):
    global CRAWLER, DEBUG
    
    DEBUG and print(f'\n\n{GetTimestamp()} - Quitting...\n')
    
    try:
        if graceful and not CRAWLER.tracker.attemptedQuit:
            CRAWLER.options.attemptedQuit += 1
        else:
            raise Exception()
    except Exception:
        os._exit(1)


def GetTimestamp(file=False):
    """ Return a formatted timestamp. """
    if file:
        d = str(datetime.now().strftime(f'%m_%d_%y %H_%M_%S'))
    else:
        d = str(datetime.now().strftime(f'%H:%M:%S'))
    
    return d


class Options():
    """ Handle all global options and trackers. """
    
    def __init__(self, crawler):
        i = crawler.input
        self.attemptedQuit = False
        itemized = crawler.links.itemized
        
        # Default values.
        self.age = 60  # Itemized list only.
        self.pages = 5
        self.risk = 3
        self.profit = 5000
        self.buy = 0
        self.minUnits = 1
        self.maxUnits = 200
        self.exclude = []
        self.require = []
        # Applies to either scan.
        self.accuracy = 3
        self.interval = 5
        
        # Use itemized list or not.
        if itemized:
            r = i(f'Scan {len(crawler.links)} listed items [y]: ')
            if r and r != 'y':
                crawler.links.itemized = False
        
        # Some options are only relevant for an itemized links list, and others only for a global search.
        if crawler.links.itemized:
            try:
                self.age = int(i('Maximum age of listing in minutes [60]: '))
            except Exception:
                pass
        else:
            try:
                self.pages = int(i('Search result pages to scan every round [5]: '))
            except Exception:
                pass
            
            try:
                self.risk = int(i('Maximum Price / Profit risk ratio [3]: '))
            except Exception:
                pass
            
            try:
                self.profit = int(i('Minimum profit-category in gold [5000]: '))
            except Exception:
                pass
            
            try:
                self.buy = int(i('Maximum price per listing: '))
            except Exception:
                pass
            
            try:
                self.minUnits = int(i('Minimum amount of units per listing: '))
            except Exception:
                pass
            
            try:
                self.maxUnits = int(i('Maximum amount of units per listing [200]: '))
            except Exception:
                pass
            
            self.exclude = i('Exclude all substrings from results (Example: key, writ): ')
            self.exclude = [x.strip().lower() for x in self.exclude.split(',') if x.strip()]
            
            self.require = i('Require any of substrings in results (Example: of power, necro): ')
            self.require = [x.strip().lower() for x in self.require.split(',') if x.strip()]
        
        # Display further options.
        try:
            self.accuracy = int(i('Item price-estimation accuracy by search pages [3]: '))
        except Exception:
            pass
        
        try:
            self.interval = int(i('Delay between each round in minutes [5]: '))
        except Exception:
            pass
        

class Proxies():
    """ Load proxies from file and handle proxy rotation. """
    
    def __init__(self, crawler):
        self.crawler = crawler
        self.list = []  # Empty. Defaults to no proxy.
        self.index = 0  # Current proxy index.

        try:
            with open('proxies.txt') as f:
                # Not empty. Starts as a URL.
                self.list = [line.strip() for line in f if line.strip().startswith('http')]

            # Not empty.
            if not self.list:
                raise Exception()

            # Shuffle for when script is restarted often.
            shuffle(self.list)
        except Exception:
            x = input('Failed to load proxies from file! Continue without a proxy? [n]: ')
            if not x:
                ForceQuit(graceful=False)

    def GetProxy(self):
        """" Return the next proxy, or '' for no proxy used - but then sleep() too. """

        if not self.list:
            # Insert a delay without proxies.
            sleep(10)
            return ''
        
        try:
            p = self.list[self.index]
        except Exception:
            # Start over.
            self.index = 0
            p = self.list[self.index]
        finally:
            proxy = p
            self.index += 1

        # Crawler tracking.
        self.crawler.tracker.proxyFailed += 1
        self.crawler.proxy = proxy
        
        return proxy


class Links():
    """ Either load items to scan from file, or use generic recent search results. """
    
    searchURL = ('https://us.tamrieltradecentre.com/pc/Trade/SearchResult?ItemID=&SearchType=Sell&ItemNamePattern='
                 '&ItemCategory1ID=&ItemCategory2ID=&ItemCategory3ID=&ItemTraitID=&ItemQualityID=&IsChampionPoint=false'
                 '&LevelMin=&LevelMax=&MasterWritVoucherMin=&MasterWritVoucherMax=&AmountMin=&AmountMax=&PriceMin=&PriceMax=')
    
    def __init__(self, crawler):
        self.itemized = False  # Item list has loaded.
        self.crawler = crawler
        
        # Set finally after Options() finished.
        self.list = []
        
        try:
            with open('items.txt') as f:
                # Not empty. Starts as a URL.
                self.list = [line.strip() for line in f if line.strip().startswith('http')]

            # Empty.
            if not self.list:
                raise Exception()

            self.itemized = True
        except Exception:
            x = input('Failed to load items from file! Continue with a general scan? [y]: ')
            if x and x != 'y':
                ForceQuit(graceful=False)

    def __iter__(self):
        """ Yield all links. """
        for i in self.list:
            yield i
    
    def __len__(self):
        """ Length of links list. """
        return len(self.list)
    
    def UpdateList(self):
        """ Override the links list according to the user choice. """
        if not self.itemized:
            self.list = [self.searchURL]  # Mimic website url pattern.
            for i in range(2, self.crawler.options.pages + 1):
                self.list.append(f'{self.searchURL}&page={i}')


class Tracker():
    """ Track all crawler activities. """
    
    def __init__(self):
        self.attemptedQuit = 0

        self.proxyFailed = 0
        
        self.matches = 0        # Successful listing matches.
        self.listings = 0       # All listings scanned through.


class Item():
    """
        A TTC item with all its data.
        
        id
        name
        level               str
        champion            str - 'true' or 'false'
        quality
        trait               Optional.
        vouchers            Optional. For writs.

        trader              'Community' for guild trader, otherwise @player.
        location
        guild

        ppp                 int
        units               int
        buy                 int - Total price of listing.
        lastSeen            int - Last seen in minutes (Seen! not listed.)

        values              [int, ...] - Most recent listings prices.
        sell                int - Estimated worth.
        sellppp             int - Estimated worth per unit.
        risk                float - Higher number means higher risk of investment.
        profit              int - Estimated profit made by reselling the item.
        
        limited             bool - Has under 10 listings available.
        recentSales         int - How many recent sales of the item were made.
        
        digitCategory       int - How many digits are in the estimated sale-value of the item.
        profitBracket       int - The nearest profit bracket to the estimated profit-value of the item.
        
        indexAll            int - All listings counted.
        index               int - Only successful matches counted.
    """

    IdUrl = 'https://us.tamrieltradecentre.com/api/pc/Trade/GetItemAutoComplete?term='
    
    sales = {
        0:      'NOPE',
        5000:   'SALE',
        10000:  'GOOD SALE',
        20000:  'SPICY SALE',
        30000:  'HOT SALE',
        50000:  'FLAMING SALE',
    }
    
    traits = {
        '': '',  # Traits are optional.
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
    }
    
    qualities = {
        '': '',
        'any quality': '',
        'normal': 0,
        'fine': 1,
        'superior': 2,
        'epic': 3,
        'legendary': 4,
    }
    
    profit_categories = {
        # Number of digits in price. No fractions in the game.
        1: 0,
        2: 0,
        3: 0,     # Hundreds.
        4: 0,     # Thousands.
        5: 0,
        6: 0,
        7: 0,     # Millions.
        8: 0,
        9: 0,
        10: 0,
    }

    def __init__(self, e, crawler):
        """ Use the Element() e to extract the item data. """

        self.crawler = crawler
        
        self.time = GetTimestamp()
        self.indexAll = crawler.tracker.listings

        cols = e.xpath('td')
        c = cols[0]
        
        path = 'div[1]/text()'
        self.name = c.xpath(f'string({path})').strip()

        self.SetId()
        
        self.SetChamp(c)
        
        self.SetLevel(c)
        
        self.SetQuality(c)
        
        path = 'img/@data-trait'
        self.trait = c.xpath(f'string({path})').strip()
        
        self.SetVouchers(c)
        
        c = cols[1]
        
        # "Community" or user name.
        path = 'div/text()'
        self.trader = c.xpath(f'string({path})').strip()
        
        c = cols[2]
        
        self.SetLocation(c)
        
        c = cols[3]
        
        self.SetPrice(c)
        
        c = cols[4]
        
        path = './@data-mins-elapsed'
        self.lastSeen = int(float(c.xpath(f'string({path})').replace(',', '')))
        
        # Assigned later.
        self.values = []
        self.sell = 0
        self.sellppp = 0
        self.index = 0
        self.risk = 0
        self.profit = 0
        self.digitCategory = 0
        self.profitBracket = 0
        self.limited = False
        self.recentSales = 0
    
    def SetId(self, retry=False):
        """ Retry a failed connection until success, and set the item's id. """
        c = self.crawler
        name = self.name
        link = self.IdUrl + name
        
        if retry:
            # New proxy. Handles tracking.
            proxy = c.proxies.GetProxy()
        else:
            # Use last proxy.
            proxy = c.proxy
        
        try:
            r = requests.get(link, headers={'https': proxy})
        except Exception:
            raise

        if r.status_code != requests.codes.ok:
            self.SetId(True)
            return

        try:
            j = r.json()
            self.id = int(j[0]['ItemID'])
        except Exception:
            # Any unexpected error.
            self.SetId(True)
            return

    def SetChamp(self, c):
        try:
            path = 'div[3]/img/@src'
            champion = c.xpath(f'string({path})').strip()
            if not champion:
                raise Exception()
        except Exception:
            path = 'div[2]/img/@src'
            champion = c.xpath(f'string({path})').strip()
        
        # /Content/icons/nonvet.png or /Content/icons/championPoint.png
        if 'championPoint' in champion:
            self.champion = 'true'
        else:
            self.champion = 'false'

    def SetLevel(self, c):
        try:
            path = 'div[3]'
            level = c.xpath(f'string({path})').split()[-1]
            # Verify value.
            int(level)
        except Exception:
            path = 'div[2]'
            level = c.xpath(f'string({path})').split()[-1]
            
        self.level = level

    def SetQuality(self, c):
        path = 'img/@class'
        parts = c.xpath(f'string({path})').split()
        part = [x for x in parts if 'quality' in x][0]
        self.quality = part.split('-')[-1]

    def SetVouchers(self, c):
        try:
            path = 'div[2]/text()'
            v = c.xpath(f'string({path})')
            p = v.split()[1]
            self.vouchers = int(p)
        except Exception:
            # Not a writ.
            self.vouchers = ''
            pass

    def SetLocation(self, c):
        try:
            self.location = c.xpath(f'string(div[1]/text())').strip()
            self.guild = c.xpath(f'string(div[2]/text())').strip()
        except Exception:
            # No details for some private user trades.
            self.location = ''
            self.guild = ''

    def SetPrice(self, c):
        parts = c.xpath(f'string()').split()
        
        self.ppp = int(float(parts[0].replace(',', '')))
        self.units = int(float(parts[2].replace(',', '')))
        self.buy = int(float(parts[4].replace(',', '')))

    def GetSale(self, n):
        return self.sales[n]
    
    def GetTrait(self, s):
        return str(self.traits[s.lower()])
    
    def GetQuality(self, s):
        return str(self.qualities[s.lower()])

    def SetValue(self):
        """
            As part of Evaluate(), calculates the item's value per unit.
            
            Method:
            
            p = [15000, 15000, 14500, 22500, 33000, 9999, 27000, 35500, 150000, 200000]

            1. Count how many digits are in each number: Singles, Doubles, Hundreds, Thousands, Tens of, Hundreds of, Millions.
                (8 Tens of, 2 Hundreds of.)

            2. Select the most used digits state. (Tens of.) [15000, 15000, 14500, 22500, 33000, 9999, 27000, 35500]

            3. Round all up or down (by nearness to middle) to one digit under category.
                [15000, 15000, 15000, 23000, 33000, 10000, 27000, 36000]

            4. Get the mean(). (21750)

            5. Get the nearest sale prices below and over the mean. (15000, 33000)

            Return all 3 last results rounded. ("22,000 [15,000, 33,000]")
        """
        
        categories = self.profit_categories.copy()
        
        # Count the digits for every value, to find the most common.
        for v in self.values:
            categories[len(str(v))] += 1

        # Get the biggest one. If more than one, get the bigger category.
        self.digitCategory = max(reversed(sorted(categories.keys())), key=(lambda k: categories[k]))

        # Keep only the values from that category.
        kept = []
        for v in self.values:
            cat = len(str(v))
            if cat == self.digitCategory:
                # Round to two digits under category. (1,553 -> 1,550)
                r = round(v, -self.digitCategory + 3)
                kept.append(r)

        # Add values from another category if it has a meaningful amount of listings.
        for v in self.values:
            cat = len(str(v))
            # Skip main category.
            if cat == self.digitCategory:
                continue
            # NOTE Hard to say what number makes sense. Ratios don't make sense in any format.
            if categories[cat] >= 10:
                # Round to two digits under category.
                r = round(v, -self.digitCategory + 3)
                kept.append(r)
        
        # Statistical mean().
        v = mean(kept)
        # No fractions.
        v = int(v)
        # Round to two digits under category.
        v = round(v, -int(self.digitCategory) + 3)
        
        self.sellppp = v
        self.sell = self.sellppp * self.units

    def Evaluate(self):
        """
            Estimate the item's value from the values of further recent listings.
            
            Return the item if it passes all the filters, or None.
        """
        
        opts = self.crawler.options
        
        self.SetValue()
        
        # Find my potential profit. Stacks calculate selling the whole stack.
        # Example: 120g * 37 - 35g * 37 = 4440 - 1295 = 3,145g EARNINGS
        self.profit = self.sell - self.buy
        # Round to two digits under category.
        self.profit = round(self.profit, -int(self.category) + 3)
        
        # Find nearest sale category value.
        # Example: profit = 3,145g matches category [5000]. 1,232g would match [0].
        self.profitBracket = min(list(self.sales), key=lambda x: abs(x - self.profit))
        
        # For the same profit, the smaller the purchase the better.
        # If buy and sell values are equal, then there's no assumed risk. NOTE Or is there?
        # Example: buy 1,000g / sell 2,000g = 0.5 risk
        if self.profit:
            self.risk = self.buy / self.profit
        
        # The advanced cost is too high for the potential profit.
        # Example: BUY 100k, SELL 105k, PROFIT 5k. risk = 100 / 5 = 20
        # NOTE add < 0 case?
        if opts.risk and self.risk > opts.risk:
            return
        
        # Limited supply items don't even have 10 results in TTC.
        if len(self.values) < 10:
            self.limited = True
        
        return self
    
    def CompareItems(self, item):
        """ Returns True if two items are estimated to be the same listing. """
        return (self.location == item.location and
                self.guild == item.guild and
                self.ppp == item.ppp and
                self.units == item.units)


class Crawler():
    """
        Handles crawling webpages, one at a time (not async.)
        - Load all other classes.
        - Print results as a webpage file.
    """

    # The format of the html page where all the results are saved, live.
    html = (
        "<!DOCTYPE html>\n"
        "<html>\n"
        "<head>\n"
        "    <meta charset='utf-8'>\n"
        "    <meta http-equiv='X-UA-Compatible' content='IE=edge'>\n"
        "    <title>Deal Finder</title>\n"
        "    <meta name='viewport' content='width=device-width, initial-scale=1'>\n"
        "</head>\n"
        "<body>\n"
        "<table style='width:50%; margin-left: 25%; border: 1px solid grey;'>\n"
        "    <tr>\n"
        "        <th> - </th>\n"
        "        <th>#</th>\n"
        "        <th>Units</th>\n"
        "        <th>Name</th>\n"
        "        <th>Quality</th>\n"
        "        <th>Trait</th>\n"
        "        <th>Vouchers</th>\n"
        "        <th>Location</th>\n"
        "        <th>Guild</th>\n"
        "        <th>Total Price</th>\n"
        "        <th>Piece Price</th>\n"
        "        <th>Sell Value</th>\n"
        "        <th>Piece Value</th>\n"
        "        <th>Sale Category</th>\n"
        "        <th>Profit</th>\n"
        "        <th>Recent Sales</th>\n"
        "        <th>All Values</th>\n"
        "        <th>Limited Supply</th>\n"
        "    </tr>\n"
    )
    row = (
        "    <tr>\n"
        "        <td>{0}</td>\n"
        "        <td>{1}<td>\n"
        "        <td>{2}</td>\n"
        "        <td>{3}</td>\n"
        "        <td>{4}</td>\n"
        "        <td>{5}</td>\n"
        "        <td>{6}</td>\n"
        "        <td>{7}</td>\n"
        "        <td>{8}</td>\n"
        "        <td>{9}</td>\n"
        "        <td>{10}</td>\n"
        "        <td>{11}</td>\n"
        "        <td>{12}</td>\n"
        "        <td>{13}</td>\n"
        "        <td>{14}</td>\n"
        "        <td>{15}</td>\n"
        "        <td>{16}</td>\n"
        "        <td>{17}</td>\n"
        "    </tr>\n"
    )
    close = (
        "</table>\n"
        "</body>\n"
        "</html>\n"
    )

    def __init__(self):
        # Track the currently used proxy for reuse.
        self.proxy = None
        # Track saved (filtered) listings.
        self.matches = []
        
        # Load item links from file or setup a general scan.
        self.links = Links(self)
        
        # Load options. Get user input.
        self.options = Options(self)
        
        # Update the links list per user choice.
        self.links.UpdateList()
        
        # Track all activites.
        self.tracker = Tracker()
        
        # Used in the save() filename.
        self.time = GetTimestamp(True)
        
        # Load proxies.
        self.proxies = Proxies(self)
        
        self.print(f'Crawler intialized. Scanning {len(self.links)} links...', True)
        
        # Start the scan.
        while not self.tracker.attemptedQuit:
            for link in self.links:
                # Analyze page.
                try:
                    self.scan(link)
                except (KeyboardInterrupt, SystemExit):
                    ForceQuit()
            
            i = 0
            while not self.tracker.attemptedQuit and i < self.options.interval * 60:
                self.print(f'Finished a scrape, waiting {(self.options.interval * 60) - i} seconds for next round...', flush=True)
                sleep(1)
                i += 1

    def print(self, s, debug=False, flush=False):
        """ Pretty print. """
        global DEBUG
        # Only print debugs if enabled.
        if debug and not DEBUG:
            return
        
        # Prefix.
        pre = ''
        if debug:
            pre = '- '
        
        end = '\n'
        timestamp = f'{GetTimestamp()} '
        if flush:
            end = '\r'
            timestamp = ''
        
        print(f'{timestamp}{pre}{s}', end=end, flush=flush)
        
        if not flush:
            print()
    
    def input(self, s):
        """ Pretty input. """
        result = input(s)
        print()  # Newline.
        return result

    def save(self, items):
        """ Create or add to the save file with formatting. """
        # Format into html.
        content = ''
        for item in items:
            values = ''
            vlen = len(item.values)
            ivalues = sorted(item.values)
            if vlen > 10:
                # Split into lines.
                v = []
                for i in range(ceil(vlen / 10)):
                    start = i * 10
                    end = (i + 1) * 10
                    v.append(str(ivalues[start:end]))
                # Add a newline between parts.
                values = '\n'.join(v)
            
            content += self.row.format(item.time, item.index, item.units, item.name, item.quality, item.trait, item.vouchers, item.location,
                                       item.guild, item.buy, item.ppp, item.sell, item.sellppp, item.profitBracket,
                                       item.profit, item.recentSales, values, item.limited)

        self.print(f'Saving {len(items)} items to file...', True)
        
        filename = f'DealFinder_{self.time}.html'
        
        # Create file on first call.
        if not os.path.isfile(filename):
            with open(filename, 'w') as f:
                f.write(self.html + self.close)
        
        # TODO: Split files to 1,000 items each?
        
        if content:
            # Get old content, remove ending, add new content, add ending.
            with open(filename, 'r+') as f:
                lines = f.readlines()
                # Remove ending.
                old = lines[:-3]
                # Recompose.
                old = '\n'.join(old)
                # Add and reclose.
                new = old + content + self.close
                # Save from start.
                f.seek(0)  # TODO Seek before self.close and only add to file, instead of full rewrite.
                f.write(new)

    def connect(self, link, retry=False):
        """
            Connect until success, and return the items Element() list.
            
            retry - Identify the call as a retry attempt, for logging.
        """
        # TODO Implement retries? Not critical as all proxies rotate anyways.
        
        # if retry:
            # New proxy. Handles tracking.
            
            # self.print(f'Retrying connection with proxy #{self.proxies.index}...', True, True)
        # else:
        #     # Use last proxy.
        #     proxy = self.proxy
        
        # Always switch proxy.
        proxy = self.proxies.GetProxy()
        
        try:
            r = requests.get(link, headers={'https': proxy})
        except Exception:
            self.print(f'Failed proxy #{self.proxies.index}: {format_exc()}', True)
            raise  # TODO Not raise? Kills script for no reason?
        
        try:
            root = html.fromstring(r.content)
            
            items = root.xpath('//tr[@class="cursor-pointer"]')
            
            # NOTE Figuring out if captcha is blocking this or what.
            # noMatches = root.xpath("//h4[contains(., 'No trade matches your constraint')]")
            completeCaptcha = root.xpath("//h5[contains(., 'complete the captcha')]")
            
            # Blocked by captcha!
            # not items and not noMatches
            if completeCaptcha:
                raise Exception()
        except Exception:
            items = self.connect(link, True)

        return items

    def scan(self, link):
        """ Handles all link operations. """
        items = self.connect(link)
        
        # Make an Item() object for each listing.
        setupItems = []
        for i in items:
            self.tracker.listings += 1
            
            self.print(f'Scanning item #{self.tracker.listings}...', True, True)
            
            try:
                item = Item(i, self)
            except Exception:
                # Any errors on the website.
                self.print(f'Failed item #{self.tracker.listings} creation: {format_exc()}', True)
                continue
            
            not item and self.print(f'Failed item #{self.tracker.listings} in creation.', True)
            
            # Track setup items.
            if item:
                setupItems.append(item)
        
        # Populate values and estimates for items. Filter.
        matches = []
        for i in setupItems:
            try:
                item = self.analyze(i)
            except Exception:
                # Connection impasses or website issues.
                self.print(f'Failed item #{self.tracker.listings} in analyze: {format_exc()}', True)
                continue
            
            not item and self.print(f'Failed item #{self.tracker.listings} in analyze.', True)
            
            # Track filtered items.
            if item:
                self.tracker.matches += 1
                item.index = self.tracker.matches
                # Add.
                matches.append(item)
        
        if matches:
            # Track.
            self.matches += matches
            
            # Save to file.
            self.save(matches)
    
    def analyze(self, item):
        """
            Get the item's listed values and estimate its value.
            Return only an item that passes all filters.
        """
        
        opts = self.options
        links = self.links
        
        if links.itemized:
            # Too old.
            if item.lastSeen > opts.age:
                return
            
            # Item already listed before.
            for i in self.matches:
                if item.CompareItems(i):
                    # Also, remove a listing that next round gets too old.
                    if item.lastSeen + (opts.interval * 60) > opts.age:
                        self.matches.remove(i)
                    return
            
            # Acceptable.
            return item
        else:
            # Purchase is too expensive.
            if opts.buy and item.buy > opts.buy:
                self.print(f'Failed item #{self.tracker.listings} in analyze for opts.buy.', True)
                return
            
            # Too few or too many units.
            if opts.minUnits and item.units < opts.minUnits:
                self.print(f'Failed item #{self.tracker.listings} in analyze for opts.minUnits.', True)
                return
            if opts.maxUnits and item.units > opts.maxUnits:
                self.print(f'Failed item #{self.tracker.listings} in analyze for opts.maxUnits.', True)
                return
            
            # Exclude substrings from name. Case insensitive.
            for s in opts.exclude:
                if s in item.name.lower():
                    self.print(f'Failed item #{self.tracker.listings} in analyze for opts.exclude.', True)
                    return
            
            # Require at least one substring match in name. Case insensitive.
            if opts.require:
                m = False
                for s in opts.require:
                    if s in item.name.lower():
                        m = True
                if not m:
                    self.print(f'Failed item #{self.tracker.listings} in analyze for opts.require.', True)
                    return
        
        end = opts.accuracy + 1
        for page in range(1, end):
            sleep(uniform(1.5, 2.5))  # Delay between pages.
            
            self.print(f'Scanning values page #{page} of {opts.accuracy} for {item.name}...', True, True)
            
            link = (f'https://us.tamrieltradecentre.com/pc/Trade/SearchResult?ItemID={item.id}&SearchType=Sell'
                    f'&ItemNamePattern=&ItemCategory1ID=&ItemCategory2ID=&ItemCategory3ID='
                    f'&ItemTraitID={item.GetTrait(item.trait)}&ItemQualityID={item.GetQuality(item.quality)}'
                    f'&IsChampionPoint={item.champion}&LevelMin={item.level}&LevelMax={item.level}'
                    f'&MasterWritVoucherMin={item.vouchers}&MasterWritVoucherMax={item.vouchers}'
                    f'&AmountMin=&AmountMax=&PriceMin=&PriceMax=&page={page}')
            
            items = self.connect(link)
            # NOTE Should I assume I'll always get at least 1 item in the result? Infinite loop possible in connect().
            for i in items:
                # NOTE Uses the same operations from Item().
                cols = i.xpath('td')
                c = cols[3]
                parts = c.xpath(f'string()').split()
                ppp = int(float(parts[0].replace(',', '')))
                
                item.values.append(ppp)
                
                # Count recent sales.
                if item.lastSeen <= 60:
                    item.recentSales += 1
        
        # Set value estimates.
        if not item.Evaluate():
            return
        
        # Acceptable.
        return item


# Not designed for modulation.
if __name__ == "__main__":
    # Catch interruptions.
    signal.signal(signal.SIGINT, ForceQuit)
    
    # Crawl links.
    CRAWLER = Crawler()
