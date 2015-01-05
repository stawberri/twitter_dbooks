# twitter_dbooks v1

[![Deploy to Heroku](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

twitter_dbooks is a pre-written twitter_ebooks bot that allows *anyone* to set up their very own anime image tweeting bot. See [@kangaroo_ebooks](https://twitter.com/kangaroo_ebooks) for an example bot.

## Installation

All you need is a web browser and a couple minutes to set up your new image bot! I'd be really grateful if you told people you're using my code, though! If you need any help, please feel free to ask me on Twitter. I'm [@stawbewwi](https://twitter.com/stawbewwi).

1.  **Starting out**

    Click my pretty [Deploy to Heroku](https://heroku.com/deploy) button above.

2.  **Fill out your environment variables (settings)**

    You can set your app name to anything you like. It (probably) won't be visible to anyone else unless you tell them.

    *   **Twitter Settings**

        ```
        TWITTER_KEY - Twitter Consumer Key
        TWITTER_SECRET - Twitter Consumer Secret
        TWITTER_TOKEN - Twitter Access Token
        TWITTER_TSECRET - Twitter Access Token Secret
        ```

        Unless you intend to have your own Twitter account tweet images, you'll want to [create a new Twitter account](https://twitter.com/signup) for your bot. Remember, if you use Gmail (and probably some other email services), you don't even need to create a new email account. Just sign up with `youremail+mylewdbot@gmail.com` or something like that as your email. It'll work!

        Once you have a new Twitter account all registered and stuff, head over to [Twitter's Application Management page](https://apps.twitter.com/) to [create a new app](https://apps.twitter.com/app/new) (or find an existing one). Don't worry too much about what you put into those boxes, because they're mainly for apps that are for other people to use. You're just making an app for a bot to use. For example, if you don't have a Website to type into Website, just type in `http://twitter.com/`.

        You should end up on your new Twitter App's Details page. Head over to its "Permissions" tab. While "Read and Write" is enough for now, you might want to set it to "Read, Write, and Access direct messages" to future proof your API keys and stuff. That's one of the reasons why you should have made a new account for your bot! Make sure you save your settings. Your bot can't do anything if it can only read timelines!

        Now head over to your app's "Keys and Access Tokens" tab. You should see two rows of random characters that you can use to fill out part of your Heroku deployment form now! Just copy your Consumer Key and Secret over to `TWITTER_KEY` and `TWITTER_SECRET`, respectively. Once you've done that, scroll down a bit to "Your Access Token" and click, "Create my Access Token" if you need to. Ensure that your "Access Level" says that your app can write (at least), and then copy your Access Token and Secret over to `TWITTER_TOKEN` and `TWITTER_TSECRET`, respectively!

    *   **Danbooru Settings**

        ```
        DANBOORU_LOGIN - Danbooru Username (optional)
        DANBOORU_KEY - Danbooru API Key (optional)
        ```

        These are entirely optional, but even basic accounts have a greatly increased API request cap over non-logged in accounts! Basically, for your image tweeting bot to work, it'll have to go and look at Danbooru a lot (multiple times just to tweet one picture). Each time it looks at Danbooru, it uses up one "request." If your bot looks at Danbooru too many times in a really short timeframe, Danbooru will get embarrassed and refuse to let your bot look at it any more for a while! If you have an account, though, Danbooru will feel more familiar around your bot and be glad to let it look at it more!

        After you [sign up for Danbooru](https://danbooru.donmai.us/users/new), just type your login name into `DANBOORU_LOGIN` and then head over to your profile. You'll find your "API Key" somewhere on there, and then you can use that to fill in `DANBOORU_KEY`!

        Oh, and just in case you might use your account more later on, you might want to remember ***not*** to use the same login name on Danbooru as you do elsewhere, unless you're an exhibitionist!

    *   **Content Setting**

        ```
        DANBOORU_TAGS - Search Tags (optional) - default: *
        ```

        This is what sets your bot apart from all the other bots! You'll need to do [your own research](http://danbooru.donmai.us/wiki_pages/43049) on this though, since if I tried to list all the tags you could use here, this installation guide would get *reallly* long! You might want to [test out your search](http://danbooru.donmai.us/wiki_pages/43037) on Danbooru itself before you set up your bot to do a particular search, though. If you restart your Twitter bot too many times in a really short timeframe (and it's a stupidly low number), Twitter will get annoyed and refuse to let your bot start anymore for a couple minutes.

    *   **Patience Setting**

        ```
        TWEET_INTERVAL - Time Between Tweets - default: 30m
        ```

        Here, you can decide how long your bot waits between tweets! You can learn more about what you can set this to on [twitter_ebooks's scheduler's github page](https://github.com/jmettraux/rufus-scheduler), but you can set it to any number ending in s, m, h, d, or y to set it to that many seconds, minutes, hours, days, or years, respectively! I recommend minutes. If you make it too slow, you might as well just tweet your own images, and if you make it too fast, Twitter will get annoyed and put your bot in time-out.

6.  **Deploy**

    Click Heroku's big purple finish button. Wait for it to build your bot.

7.  **Scale**

    Unfortunately, Heroku is pretty lazy, and doesn't like doing anything other than what you tell it to do! You just told it to build your bot, and it was more than happy to do so, but it didn't actually start running it for you.

    1.  **Finding your app's Resources tab**

        Under Heroku's "Your app was successfully deployed" message, click on "make your first edit." You'll find yourself on a super confusing page you don't need to worry about! Go ahead and select "Resources" near the top (it's a tab).

        If you already accidentally left that page, go ahead and head over to your [main Heroku Dashboard](https://dashboard.heroku.com/) and click on the name of your bot's app. You should already be on its "Resources" tab, but go ahead and click on it if you aren't.

    2.  **Clicking Edit**

        On your Resources tab, you'll find a section labeled Dynos. It should have a bar labeled worker in it. Click the "Edit" button to edit your dynos. Your "worker" bar should turn into a very scary looking setting bar that you can drag.

        ![Edit Dynos](https://cloud.githubusercontent.com/assets/9897819/5611557/f2d29b70-947c-11e4-8caa-1fe7cd313edd.jpg)

    3.  **Scaling your worker**

        Ensure that the little dropdown next to your worker's bar is set to 1X, unless you're rich. Very carefully drag its setting handle ever so slightly to the right, so that it now says 1.

        Ensure that the price listed next to the bar says $0, unless you're rich. If it doesn't say $0, you either forgot to ensure your Worker dyno is set to 1X, you didn't drag its settings bar to 1, or Heroku has suddenly gotten more greedy.

    4.  **Saving your settings**

        Once you're absolutely sure Heroku isn't going to charge you (because all of the dollar signs say 0), go ahead and click on your app's Dynos' "Save" button. It should be where you found its "Edit" button before.

        ![Saving Dyno Settings](https://cloud.githubusercontent.com/assets/9897819/5611611/8a697fc6-947d-11e4-9357-688c854dbd1c.jpg)

8.  **You're done!**

    Cross your fingers for good luck, and then head over to Twitter. You should see that your bot has already gotten to work!

## Configuration

You should have already set up your bot already, but changing your settings (or accessing them for future updates) is easy!

1.  Head over to your [Heroku dashboard](https://dashboard.heroku.com/) and select your app by clicking on its name.
2.  Click on your app's "Settings" tab.
3.  You can rename your app through the "Name" field available on this page.
4.  On your app's Settings tab's Config Variables section, click on "Reveal Config Vars" to open up your Config Vars editor.
5.  Scroll up a little bit, and refer to this README's installation guide to find out what you should set your config vars to.
    Don't edit the boxes with words in ALL_CAPS, though, or weird stuff might happen.

## Updates

Right now, it looks like future updates might be a bit of a hassle unless Heroku adds in some kinda updating feature.
To perform updates, you'll need to:

1.  Locate and somehow save your current bot's settings, probably by manually copying them to Notepad or something.
2.  Shut down or delete your current bot's heroku app, using the scary red button at the bottom of its Settings tab.
3.  Redeploy an entirely new bot to Heroku, pasting in your current bot's settings.

Of course, if you have Heroku set up on your computer and stuff, you can also clone this repository and then push it onto Heroku yourself.
