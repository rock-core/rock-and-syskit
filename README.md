# HowTo

1. Install middleman (you might need to add `sudo` to the command):

    `gem install middleman`

2. Clone the repository:

    `git clone git@github.com:rafaelsaback/rock_website.git`

3. Go to the repository's folder and run:

    `bundle exec middleman`

And voilà! The website should be available from your localhost. Just read the middleman messages to know how exactly to open it in the browser.


# Possible Errors

If you get this error

`
ExecJS::RuntimeUnavailable: Could not find a JavaScript runtime. See https://github.com/rails/execjs for a list of available runtimes.
`

Install NodeJS with the following command

`
sudo apt-get install nodejs
`
