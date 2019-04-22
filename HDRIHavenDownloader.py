import scrapy
from scrapy.http import Request


class Spider(scrapy.Spider):
    name = "spider"
    start_urls = ['https://hdrihaven.com/hdris/category/?c=all']

    custom_settings = {
        'DOWNLOAD_WARNSIZE': 0,
        'CONCURRENT_REQUESTS': 1,
    }

    count = 0

    def parse(self, response):
        for href in response.css('div#hdri-grid > a::attr(href)').extract():
            yield Request(
                url=response.urljoin(href),
                callback=self.parse_link
            )

    def parse_link(self, response):
        for href in response.css('div#hdri-info a[href$="&r=4k"]::attr(href)').extract():
            yield Request(
                url=response.urljoin(href),
                callback=self.parse_redirect
            )

    def parse_redirect(self, response):
        for href in response.css('div#page-wrapper a[href$="4k.hdr"]::attr(href)').extract():
            yield Request(
                url=response.urljoin(href),
                callback=self.save_link
            )

    def save_link(self, response):
        path = response.url.split('/')[-1]
        self.count += 1
        self.logger.info('Saving #%d HDR %s', self.count, path)
        with open(path, 'wb') as f:
            f.write(response.body)
