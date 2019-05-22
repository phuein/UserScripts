import requests
from urllib.parse import quote

import time
# import codecs
import re
import random
import signal
# import sys
import os

DEBUG = 0

domain = 'https://gumroad.com'

# Ctrl+C stops page fetching loop,
# while saving results.
interrupted = False


def signal_handler(sig, frame):
    global interrupted
    print('Interrupted! Finishing...')
    interrupted = True


signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)


# Get user settings.
query = ''
while not query:
    query = input('Enter search query: ')

maxResults = input('Max result pages [1]: ')
maxResults = int(maxResults) if maxResults else 1

maxPrice = input('Max price per item [0]: ')
maxPrice = float(maxPrice) if maxPrice != '' else 0


# Log results to a new file.
def log(text, f='txt'):
    t = time.strftime("%Y%m%d_%H%M%S")

    with open(f'gumroad_results_{t}.{f}', 'w', encoding='utf-8') as file:
        file.write(text)


# Return [(uniqueID str, price float), ..] from gumroad search results page.
def scrape(page):
    try:
        r = requests.get(domain + page)
    except Exception as err:
        DEBUG and print(f'Failed to connect: {err}')
        return []

    source = r.text
    # print(source)

    # data-unique-permalink=\"OJlw\"
    n = 'data-unique-permalink=\\"'
    # itemprop=\"price\"\u003e$149+\u003c
    p = 'itemprop=\\"price\\"\\u003e'
    # \n\u003cstrong\u003e\nvoxel plugin™ PRO\n\u003c/strong\u003e\n
    t = '\\u003cstrong\\u003e\\n'

    res = []
    lastIndex = 0
    for i in range(8):
        # Get item id for linking.
        a = source.find(n, lastIndex)

        # No more items to list, so finish.
        if a == -1:
            break
        b = source.find('\\"', a + len(n))
        name = source[a + len(n):b]
        DEBUG and print(name)

        # Get item price.
        a = source.find(p, lastIndex)  # Start from the last result's index.
        b = source.find('\\u003c', a + len(p))
        price = source[a + len(p):b]
        DEBUG and print(price)
        # Extract number only.
        price = re.findall(r'\d+', price)

        # BUG: No price available.
        if not price:
            break
        price = price[0]

        # Get item title.
        a = source.find(t, lastIndex)
        b = source.find('\\n', a + len(t))
        title = source[a + len(t):b]
        DEBUG and print(title)

        # Add item as tuple.
        res.append((name, float(price), title))
        lastIndex = b
    return res


# Main loop.
results = []
pageCount = '1'


def run():
    global pageCount
    print()  # Skip a line.
    for i in range(maxResults):
        # Signal interruption from system or user.
        if interrupted:
            break

        not DEBUG and print(f'Searching...{("."*i)}', end="\r", flush=True)

        # Increments of 8, so 1, 9,.. and so on.
        v = i * 9 if i > 1 else 1

        link = f'/discover_search?from={v}&query={quote(query)}'

        # Imitate human delay.
        if i > 1:
            # 1-3 seconds.
            z = random.randrange(10, 30) / 10
            DEBUG and print(f'Page {i} - Sleeping for {z} seconds...')
            time.sleep(z)

        res = scrape(link)

        # Finished early.
        if not res:
            DEBUG and print('No more results.')
            break

        pageCount = str(i)

        # Get id's and prices for results in page.
        # Save the ones below the maximum price limit.
        for item in res:
            uid, price, title = item
            if price <= maxPrice:
                x = {
                    'id': uid,
                    'price': price,
                    'title': title,
                }

                # NOTE: Slow check, but keeps order.
                if x not in results:
                    results.append(x)


def finish():
    global pageCount

    DEBUG and print(results)
    # Log to file.
    if not results:
        text = f'No results for <b>{query}</b>.'
    else:
        text = ''
        for item in results:
            s = domain + '/l/' + item['id']
            text += f'<a href={s} target=_blank>{item["title"]}<br>'

    log(text, 'html')

    print(f'Got {len(results)} matches saved from {pageCount} pages.')
    os.system('pause')


# Calls.
run()
finish()
