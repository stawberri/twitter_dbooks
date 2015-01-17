# @_dbooks v2: Tagging Along

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

@_dbooks is a pre-written [twitter_ebooks](https://github.com/mispy/twitter_ebooks) bot that allows *anyone* to set up their very own anime image tweeting bot. Unlike most other image tweeting bots, @_dbooks doesn't require you to maintain a collection of images (though you could, if you wanted to). It automatically tweets images from the ever-expanding [image cataloging site Danbooru](http://danbooru.donmai.us/posts?tags=rating%3As), filtered by your choice of search parameters. As Danbooru gains new images, so will your bot.

See [@kangaroo_dbooks](https://twitter.com/kangaroo_dbooks) for an example bot that tweets the most popular images from a day ago.

## Installation

I'm gunnya try to make some kind of installation tutorial eventually, but for now, you should see if you can figure out how to install your bot by reading about @_dbooks's configuration below! It might seem a little daunting, but it's really pretty simple! If you need help, please feel free to [ask me on twitter](http://twitter.com/stawbewwi).

## Configuration

All bot configuration is now done through tags. For more information about how tags work, Danbooru's wiki has [a nice page about it](http://danbooru.donmai.us/wiki_pages/43049). Danbooru tags obviously aren't enough to configure your bot, though, so I extended them with my own %tags! They all start with `%`, and pretty much work just like Danbooru's tags. %Tags that have a `:` in them start with a name, and then let you type some kinda value behind them, and %tags that don't have a `:` are optional, and only have an effect when you include them. For example, if you include `%no_deleted` in your tags, your bot won't tweet deleted posts anymore, but it will if you leave it out!

All %tags (tags that start with `%`) don't count toward your Danbooru tag limit.

%tag                      | Default | What it does
--------------------------|---------|---------------
`%twitter_key:`           |         | Twitter Consumer Key
`%twitter_secret:`        |         | Twitter Consumer Secret
`%twitter_token:`         |         | Twitter Access Token
`%twitter_token_secret:`  |         | Twitter Access Token Secret
`%danbooru_login:`        |         | Danbooru Username (optional)
`%danbooru_api_key:`      |         | Danbooru API Key (optional)
`%owner:`                 |         | Your own user ID number or username (optional)
`%every:`                 | `never` | Time between tweets in an '[1h2m3s][rufs]' format.
`%no_deleted`             | (false) | Don't tweet deleted posts
(anything else)           |         | These tags will used to search Danbooru (optional)

[rufs]: https://github.com/jmettraux/rufus-scheduler#rufus-scheduler

Note that there isn't a %tag for your bot's username.

There are two places where you can put your tags: your bot's profile, and your bot's environment variables (ENV Settings). Your ENV Settings are for things that are meant to be secret and not likely to change often, like your `%twitter_` and `%danbooru_` %tags. Everything else can go into your bot's profile description. You can type anything you want into your bot's bio, but it has to end with your tags! Just type `@_dbooks` to let your bot know to start reading its own bio, and add your tags behind it.

Note that aside from your `%twitter_` and `%danbooru_` %tags, there's no rule about where your tags have to go. You can put all of your tags inside of your ENV setting and leave `@_dbooks` out of your profile if you wish, but that would make your bot harder to tweak.

## Example Configuration

Here's an example bot that posts pictures of cat-people containing one girl every nine minutes, without being logged into Danbooru! Note that all of this example's search tags are in its profile, but you can put some into your ENV settings too! You might want to do something like that if you want to ensure that your bot posts only safe (`rating:s`) pictures all the time, forever.

**ENV setting**
```
%twitter_key:SECRETSECRETS %twitter_secret:EVENMORESECRET
%twitter_token:1234-SECRETAGAIN %twitter_token_secret:YUPITSSECRET
```

**Profile Bio**
```
Hello! I'm an example bot running: @_dbooks 1girl cat_ears %every:9m
```

## Commands

Once you set `%owner:`, you can use direct messages as a simple command-line type thing! Direct message commands work essentially the same way as profile description tags do, but all of the %tags are different now, since instead of changing settings, you'll be running commands! You also pass Danbooru search tags to your bot through DMs, and it'll search for them and immediately tweet an image matching those tags if it could find one!

Just like in your bot's profile description, you'll have to DM `@_dbooks` to your bot, followed by your tags. This is to keep you from accidentally asking your bot to tweet something embarassing.

To reiterate, config %tags (the ones above) don't work in DMs. You get these instead!

%tag                      | What your bot will do
--------------------------|-----------------------
`%version`                | Give you @_dbooks version number
`%uptime`                 | Tell you how long it has been running for
`%updater_error`          | Return a string with updater error information, if any
`%restart`                | Shut down, making Heroku restart your bot for you
(anything else)           | Run a Danbooru search and tweet a random post instantly

**Tweet an image right away**
```
@_dbooks id:1887658
```

**Restart your bot**
```
@_dbooks %restart
```

## Multiple bots

You can run multiple bots with the same app! Just create more than one ENV setting string as indicated above, string them all together, separated by commas, and dump them all into DBOOKS. Note that each bot is completely separate, so even if some of your tags are the same, you'll need to include them for each of your bots.

```
1girl %twitter_key:SECRETSECRETS %twitter_secret:EVENMORESECRET
%twitter_token:1234-SECRETAGAIN %twitter_token_secret:YUPITSSECRET, original 
%twitter_key:SECRETSECRETS %twitter_secret:EVENMORESECRET
%twitter_token:1235-SECRETAGAIN2  %twitter_token_secret:YUPITSSECRET2,
%twitter_key:SECRETSECRETS3 %twitter_secret:EVENMORESECRET3
%twitter_token:1236-SECRETAGAIN3 %twitter_token_secret:YUPITSSECRET3
```

## Updates

### From 2.x.y to 2.x.y
Updates are installed automatically when your bots restart. Just use set up your `%owner` tag and then direct message `@_dbooks %restart` to your bot, or restart it however other way you want to restart it. Heroku also automatically restarts your apps every day.

### From 1.x.y to 2.x.y
You'll have to completely reinstall. Sorry! You should already have all the details you need already, though, so just look for them again (or save them and use them again)! 

## Editing

Please note that you can't edit `bots.rb` directly, since it gets regenerated every startup. You'll want to edit `v2.rb` instead, and then set your env variable `UPDATER_OFF=true` to disable your updater.

&nbsp;

&nbsp;

&nbsp;

Thank you for considering [@_dbooks](https://twitter.com/_dbooks)!

:strawberry:
