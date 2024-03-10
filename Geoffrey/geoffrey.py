"""
Geoffrey - A very simple Discord server link remover for public channels.

This bot expects an environment variable named DISCORD_TOKEN with your Discord user full-access token.

---

IF the bot stops responding without any error, reinvite it to your server:

    https://discord.com/developers/applications

Create an executable to run on Windows startup:

    pyinstaller --onefile --noconsole --icon=geoffrey.ico geoffrey.py

More useful information:

    Module: https://github.com/Rapptz/discord.py
    Guide: https://discordjs.guide/preparations/adding-your-bot-to-servers.html#bot-invite-links
    Bot permissions: https://discord.com/developers/docs/topics/permissions
"""

import logging, sys, os
import discord

DISCORD_TOKEN = os.getenv('DISCORD_TOKEN')

logging.basicConfig(
    handlers=[
        logging.FileHandler('geoffrey.log', mode='w'),
        logging.StreamHandler(sys.stdout)
    ],
    encoding='utf-8',
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    datefmt='%m/%d/%Y %I:%M:%S %p'
)

logger = logging.getLogger(__name__)

invite_links = [
    'discord.gg/',
    'discordapp.com/invite/',
    'discord.me/server/join/',
    'discord.com/invite/'
]

allowed_links = []

# Lower case for string matching, even though invites are case sensitive.
invite_links = [x.lower() for x in invite_links]
allowed_links = [x.lower() for x in allowed_links]


class MyClient(discord.Client):
    async def on_ready(self):
        logger.info(f'Logged on as {self.user}!')

    async def on_message(self, message):
        words = message.content.lower().split()

        for word in words:
            if any(link in word for link in allowed_links):
                logger.info('Detected safe link:')
                logger.info(message.author)
                logger.info(message.created_at.astimezone().strftime('%Y-%m-%d %H:%M:%S'))
                logger.info(message.content)
                logger.info('Did nothing.')
                continue

            if any(link in word for link in invite_links):
                await message.delete()

                logger.warning('Detected invite link:')
                logger.warning(message.author)
                logger.warning(message.created_at.astimezone().strftime('%Y-%m-%d %H:%M:%S'))
                logger.warning(message.content)
                logger.warning('Deleted!')


intents = discord.Intents.default()
intents.message_content = True

if __name__ == '__main__':
    client = MyClient(intents=intents)

    if not DISCORD_TOKEN:
        error_msg = 'Environment variable DISCORD_TOKEN is not defined! Quitting...'
        logger.error(error_msg)
        sys.exit(error_msg)

    client.run(DISCORD_TOKEN)
