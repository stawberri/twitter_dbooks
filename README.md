# twitter_dbooks

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

twitter_dbooks is a pre-written twitter_ebooks bot that allows *anyone* to set up their very own anime image tweeting bot. See [@kangaroo_ebooks](https://twitter.com/kangaroo_ebooks) for an example bot.

## Installation
All you need is a web browser and a couple minutes to set up your new image bot! I'd be really grateful if you told people you're using my code, though! If you need any help, please feel free to ask me on Twitter. I'm [@stawbewwi](https://twitter.com/stawbewwi).

1.  **Starting out**

    Click my fancy [Deploy to Heroku](https://heroku.com/deploy) button above.

2.  **Configure Twitter**

    ```
    TWITTER_KEY
    TWITTER_SECRET
    TWITTER_TOKEN
    TWITTER_TSECRET
    ```

    Unless you intend to have your own Twitter account tweet images, you'll want to [create a new Twitter account](https://twitter.com/signup) for your bot. Remember, if you use Gmail (and probably some other email services), you don't even need to create a new email account. Just sign up with `youremail+mylewdbot@gmail.com` or something like that as your email. It'll work!

    Once you have a new Twitter account all registered and stuff, head over to [Twitter's Application Management page](https://apps.twitter.com/) to [create a new app](https://apps.twitter.com/app/new) (or find an existing one). Don't worry too much about what you put into those boxes, because they're mainly for apps that are for other people to use. You're just making an app for a bot to use. For example, if you don't have a Website to type into Website, just type in `http://twitter.com/`.

    You should end up on your new Twitter App's Details page. Head over to its "Permissions" tab. While "Read and Write" is enough for now, you might want to set it to "Read, Write, and Access direct messages" to future proof your API keys and stuff. That's one of the reasons why you should have made a new account for your bot! Make sure you save your settings. Your bot can't do anything if it can only read timelines!

    Now head over to your app's "Keys and Access Tokens" tab. You should see two rows of random characters that you can use to fill out part of your Heroku deployment form now! Just copy your Consumer Key and Secret over to `TWITTER_KEY` and `TWITTER_SECRET`, respectively. Once you've done that, scroll down a bit to "Your Access Token" and click, "Create my Access Token" if you need to. Ensure that your "Access Level" says that your app can write (at least), and then copy your Access Token and Secret over to `TWITTER_TOKEN` and `TWITTER_TSECRET`, respectively!

3.  **Danbooru Login**

    ```
    DANBOORU_LOGIN
    DANBOORU_KEY
    ```

    These are entirely optional, but even basic accounts have a greatly increased API request cap over non-logged in accounts! Basically, for your image tweeting bot to work, it'll have to go and look at Danbooru a lot (multiple times just to tweet one picture). Each time it looks at Danbooru, it uses up one "request." If your bot looks at Danbooru too many times in a really short timeframe, Danbooru will get embarrassed and refuse to let your bot look at it any more for a while! If you have an account, though, Danbooru will feel more familiar around your bot and be glad to let it look at it more!

    After you [sign up for Danbooru](https://danbooru.donmai.us/users/new), just type your login name into `DANBOORU_LOGIN` and then head over to your profile. You'll find your "API Key" somewhere on there, and then you can use that to fill in `DANBOORU_KEY`!

    Oh, and just in case you might use your account more later on, you might want to remember ***not*** to use the same login name on Danbooru as you do elsewhere, unless you're an exhibitionist!

4.  **Danbooru Tags**

    ```
    DANBOORU_TAGS
    ```

    This is what sets your bot apart from all the other bots! You'll need to do [your own research](http://danbooru.donmai.us/wiki_pages/43049) on this though, since if I tried to list all the tags you could use here, this installation guide would get *reallly* long! You might want to [test out your search](http://danbooru.donmai.us/wiki_pages/43037) on Danbooru itself before you set up your bot to do a particular search, though. If you restart your Twitter bot too many times in a really short timeframe (and it's a stupidly low number), Twitter will get annoyed and refuse to let your bot start anymore for a couple minutes.

5.  **Tweet Interval**

    ```
    TWEET_INTERVAL
    ```

    Here, you can decide how long your bot waits between tweets! You can learn more about what you can set this to on [twitter_ebooks's scheduler's github page](https://github.com/jmettraux/rufus-scheduler), but you can set it to any number ending in s, m, h, d, or y to set it to that many seconds, minutes, hours, days, or years, respectively! I recommend minutes. If you make it too slow, you might as well just tweet your own images, and if you make it too fast, Twitter will get annoyed and put your bot in time-out.

## Updates
Right now, it looks like future updates might be a bit of a hassle unless Heroku adds in some kinda updating feature. To perform updates, you'll need to

1.  Locate and somehow save your current bot's settings, probably by manually copying them to Notepad or something.
2.  Shut down or delete your current bot's heroku app.
3.  Redeploy an entirely new bot to Heroku, pasting in your current bot's settings.

Of course, if you have Heroku set up on your computer and stuff, you can also clone this repository and then push it onto Heroku yourself.
