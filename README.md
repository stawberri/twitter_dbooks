# twitter_dbooks v2.0.0: TBD

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

twitter_dbooks is a pre-written [twitter_ebooks](https://github.com/mispy/twitter_ebooks) bot that allows *anyone* to set up their very own anime image tweeting bot. Unlike most other image tweeting bots, twitter_dbooks doesn't require you to maintain a collection of images (though you could, if you wanted to). It automatically tweets images from the ever-expanding [image cataloging site Danbooru](http://danbooru.donmai.us/posts?tags=rating%3As), filtered by your choice of search parameters. As Danbooru gains new images, so will your bot.

See [@kangaroo_dbooks](https://twitter.com/kangaroo_dbooks) for an example bot that tweets the most popular images from a day ago.

## Configuration

Biotag                  | Default | What it does
------------------------|---------|---------------
%twitter_key:           |         | Twitter Consumer Key
%twitter_secret:        |         | Twitter Consumer Secret
%twitter_token:         |         | Twitter Access Token
%twitter_token_secret:  |         | Twitter Access Token Secret
%danbooru_login:        |         | Danbooru Username (optional)
%danbooru_api_key:      |         | Danbooru API Key (optional)
%every:                 | 30m     | Time between tweets
%deleted                | false   | Only deleted posts
%-deleted               | false   | Only non-deleted posts
