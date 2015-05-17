# lita-standup

[![Build Status](https://travis-ci.org/chriswoodrich/lita-standup.png?branch=master)](https://travis-ci.org/chriswoodrich/lita-standup)
[![Coverage Status](https://coveralls.io/repos/chriswoodrich/lita-standup/badge.png)](https://coveralls.io/r/chriswoodrich/lita-standup)

Lita-standup is a handler for Lita, meant to automate the process of the daily standup, and help teams collaborate.

## Installation

Add lita-standup to your Lita instance's Gemfile:

``` ruby
gem "lita-standup"
```

## Configuration

There's a lot here to configure.  Add the following to your ```lita_config.rb``` and interpolate your credentials as needed.

``` ruby

Lita.configure do |config|

  # General settings
  config.handlers.standup.time_to_respond =          # type: Integer, default: 60 (minutes)
  config.handlers.standup.summary_email_recipients = # type: Array, default: ['you@company.com', 'me@company.com'], required: true
  config.handlers.standup.name_of_auth_group =       # type: Symbol, default: :standup_participants, required: true

  ## SMTP Mailer settings
  config.handlers.standup.address =              'smtp.gmail.com' # type: String, required: true
  config.handlers.standup.port =                 587              # type: Integer, required: true
  config.handlers.standup.domain =               'your.host.name' # type: String, required: true
  config.handlers.standup.user_name =            'xxxxxxxxxx'     # type: String, required: true
  config.handlers.standup.password =             'xxxxxxxxxx'     # type: String, required: true
  config.handlers.standup.authentication =       'plain'          # type: String, required: true
  config.handlers.standup.enable_starttls_auto = true             # type: true || false, required: true

end


```


## Usage

After you're properly configured, manage the auth groups you'll need to use this gem.  Add yourself (or whoever else will start the standup) to the auth group :standup_admins and all participants to the auth group :standup_participants (unless you overrode this default in the config.)

To start the standup, give Lita the command ```Lita: start standup now```.

You'll get a private message asking for your answer.  Reply in the typical format with 1: things you worked on yesterday, 2: things you'll be doing today, and 3: anything that's blocking you.  Example ```standup response 1: Finished this gem. 2: Make these docs a little better. 3: Wife is making cookies and it's hard to focus.```

After the ```time_to_respond``` has elapsed, Lita will compile an email of the responses and send it to all the people in ```summary_email_recipients```.


