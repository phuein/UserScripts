import traceback
import logging
# from signal import signal, SIGINT

import discord  # noqa
from discord.ext import commands

logging.basicConfig(level=logging.ERROR)

token = 'NTg4NDcwNDkzNjg3MDU0MzY2.XQFyBw.v3wp-PB2Eep0J_cXAv8bejTonRA'


class CrownHelper(commands.Cog):
    """
        Handle events and messaging channels and users.
    """
    def __init__(self, bot):
        self.bot = bot
        self._last_member = None

    # @commands.Cog.listener()
    # async def on_member_join(self, member):
    #     channel = member.guild.system_channel
    #     if channel is not None:
    #         await channel.send('Welcome {0.mention}.'.format(member))

    @commands.Cog.listener()
    async def on_message(message):
        if message.author == client.user:
            return

        if message.content.startswith('hello'):
            await message.channel.send('Hello!')

    @commands.command()
    async def quit(self, ctx):
        await self.logout()

    @commands.command()
    async def ping(self, ctx, *, member: discord.Member = None):
        """Says pong"""
        member = member or ctx.author
        if self._last_member is None or self._last_member.id != member.id:
            await ctx.send('Pong {0.name}~'.format(member))
        else:
            await ctx.send('Pong {0.name}... This feels familiar.'.format(member))
        self._last_member = member


# client = discord.Client()
client = commands.Bot(command_prefix='!')


@client.event
async def on_ready():
    print('We have logged in as {0.user}'.format(client))


@client.event
async def on_error(event, *args, **kwargs):
    message = args[0]  # Gets the message object
    traceback.format_exc()
    # Send the message to the channel.
    await client.send_message(message.channel, "You caused an error!")


client.add_cog(CrownHelper(client))

print('Bot running...')
try:
    client.run(token)
except Exception as e:
    print(e)


# def signalHandler(signal_received, frame):
#     global bot
#     print('Quitting...')
#     async await bot.logout()
#     quit()


# signal(SIGINT, signalHandler)
