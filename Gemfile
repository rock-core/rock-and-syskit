# If you do not have OpenSSL installed, change
# the following line to use 'http://'
source 'https://rubygems.org'

# Middleman Gems
gem 'middleman', '~> 4.3'
gem 'sass'
gem 'bootstrap-sass'
gem 'susy', "~>2.2"
# Gem necessary to use execjs, hence necessary to run 'bundle exec middleman'
gem 'mini_racer'
gem 'middleman-navtree', git: 'https://github.com/doudou/middleman-navtree'
gem 'middleman-syntax'
gem 'middleman-livereload'
gem 'middleman-gh-pages'

# For faster file watcher updates on Windows:
gem 'wdm', '~> 0.1.0', platforms: [:mswin, :mingw]

# Windows does not come with time zone data
gem 'tzinfo-data', platforms: [:mswin, :mingw, :jruby]
gem 'html-proofer'

group :features do
    gem 'cucumber'
    gem 'aruba'
end

