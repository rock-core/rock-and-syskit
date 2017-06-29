# HowTo

1. Clone the repository:

    `git clone git@github.com:doudou/rock_website`

1. Go into the repository and run

    `bundle install`

1. Then

    `bundle exec middleman`

And voilà! The website should be available from your localhost. Just read the middleman messages to know how exactly to open it in the browser.

# Publishing

Run

~~~
bundle exec rake publish
~~~

# Possible Errors

If you get this error

`
ExecJS::RuntimeUnavailable: Could not find a JavaScript runtime. See https://github.com/rails/execjs for a list of available runtimes.
`

Install NodeJS with the following command

`
sudo apt-get install nodejs
`
