# twitter_dbooks v2.0.0: Tagging Along

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

twitter_dbooks is a pre-written [twitter_ebooks](https://github.com/mispy/twitter_ebooks) bot that allows *anyone* to set up their very own anime image tweeting bot. Unlike most other image tweeting bots, twitter_dbooks doesn't require you to maintain a collection of images (though you could, if you wanted to). It automatically tweets images from the ever-expanding [image cataloging site Danbooru](http://danbooru.donmai.us/posts?tags=rating%3As), filtered by your choice of search parameters. As Danbooru gains new images, so will your bot.

See [@kangaroo_dbooks](https://twitter.com/kangaroo_dbooks) for an example bot that tweets the most popular images from a day ago.

## Configuration

All bot configuration is now done through tags. For more information about how tags work, Danbooru's wiki has [a nice page about it](http://danbooru.donmai.us/wiki_pages/43049). Danbooru tags obviously aren't enough to configure your bot, though, so I extended them with my own tags! They all start with `%`, and pretty much work just like Danbooru's tags. Tags that have a `:` in them start with a name, and then let you type some kinda value behind them, and tags that don't have a `:` are optional, and only have an effect when you include them. For example, if you include `%no_deleted` in your tags, your bot won't tweet deleted posts anymore, but it will if you leave it out!

Biotag                    | Default | What it does
--------------------------|---------|---------------
`%twitter_key:`           |         | Twitter Consumer Key
`%twitter_secret:`        |         | Twitter Consumer Secret
`%twitter_token:`         |         | Twitter Access Token
`%twitter_token_secret:`  |         | Twitter Access Token Secret
`%danbooru_login:`        |         | Danbooru Username (optional)
`%danbooru_api_key:`      |         | Danbooru API Key (optional)
`%every:`                 | `never` | Time between tweets
`%no_deleted`             | (false) | Don't tweet deleted posts

There are two places where you can put your tags: your bot's profile, and your bot's environment variables (ENV Settings). Your ENV Settings are for things that are meant to be secret and not likely to change often, like your `%twitter_` and `%danbooru_` tags. Everything else can go into your profile description! You can type anything you want into your bot's bio, but it has to end with your tags! Just type in, `@_dbooks` to let your bot know you're starting to type your tags, and add your tags behind it.

Note that aside from your `%twitter_` and `%danbooru_` tags, there's no rule about where your tags have to go! You can put all of your tags inside of your ENV setting and leave `@_dbooks` out of your profile if you wish, but that would make your bot harder to tweak!

## Example Configuration

Here's an example bot that posts pictures of cat-people containing one girl every nine minutes, without being logged into Danbooru!

**ENV setting**
```
1girl %twitter_key:SECRETSECRETS %twitter_secret:EVENMORESECRET %twitter_token:1234-SECRETAGAIN %twitter_token_secret:YUPITSSECRET
```

**Profile Bio**
```
Hello! I'm an example bot running: @_dbooks cat_ears rating:s %every:9m
```

## Installation

I still have to get around to rewriting this for v2! For now, you'll just have to refer to my Configuration section above.

## Upgrades

### From 1.x.y
You'll have to completely reinstall. Sorry! You should already have all the details you need already, though, so just look for them again (or save them and use them again)! 
