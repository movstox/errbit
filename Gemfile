source 'https://rubygems.org'

# RAILS_VERSION = '5.0.7.2'
RAILS_VERSION = '7.0.1'

ruby File.read(".ruby-version")

gem 'actionmailer', RAILS_VERSION
gem 'actionpack', RAILS_VERSION
gem 'railties', RAILS_VERSION

gem 'activemodel-serializers-xml'
gem 'actionmailer_inline_css'
gem 'decent_exposure'
gem 'devise'
gem 'dotenv-rails'
gem 'draper'
gem 'errbit_plugin'
gem 'errbit_github_plugin'
gem 'font-awesome-rails'
gem 'haml'
gem 'htmlentities'
gem 'kaminari'
gem 'kaminari-mongoid'
gem 'mongoid', '8.1'
gem 'omniauth'
gem 'omniauth-rails_csrf_protection'
gem 'omniauth-github'
gem 'omniauth-google-oauth2'
gem 'rack-ssl', require: 'rack/ssl' # force SSL
gem 'rack-ssl-enforcer', require: false
gem 'rinku'
gem 'useragent'
gem 'rexml'
gem 'mutex_m'
gem 'faraday-retry'
gem 'faraday-multipart'


# Please don't update hoptoad_notifier to airbrake.
# It's for internal use only, and we monkeypatch certain methods
# gem 'hoptoad_notifier'

# Notification services
# ---------------------------------------
gem 'campy'
# Google Talk
gem 'xmpp4r', require: ["xmpp4r", "xmpp4r/muc"]
# Hoiio (SMS)
gem 'hoi'
# Pushover (iOS Push notifications)
gem 'rushover'
# Hubot
gem 'httparty'
# Flowdock
gem 'flowdock'

gem 'ri_cal'
gem 'json', '~> 2.2'

gem 'pry-rails'

group :development, :test do
  gem 'webdrivers', '~> 5.0.0'
  gem 'airbrake', '~> 4.3.5', require: false
  # gem 'rubocop', '~> 0.71.0', require: false
  # gem 'rubocop-performance', require: false
  # gem 'rubocop-rails', require: false
end

group :development do
  gem 'listen'
  gem 'better_errors', '~> 2.8'
  gem 'binding_of_caller', platform: 'ruby'
  # gem 'meta_request' # Removed by rails-upgrade.rb 2024-06-17
end

group :test do
  gem 'rails-controller-testing', '~> 1.0'
  gem 'rake', '~> 13.0'
  gem 'rspec'
  gem 'rspec-rails', require: false
  gem 'rspec-activemodel-mocks'
  gem 'mongoid-rspec', require: false
  gem 'fabrication'
  gem 'capybara'
  gem 'poltergeist'
  gem 'phantomjs'
  gem 'launchy'
  gem 'email_spec'
  gem 'timecop'
  gem 'coveralls', require: false
end

group :no_docker, :test, :development do
  gem 'mini_racer', '~> 0.6.2'
end

gem 'puma', '~> 5.5.0'
# gem 'sass-rails' # Removed by rails-upgrade.rb 2024-06-17
gem 'uglifier'
gem 'jquery-rails', '~> 4.4.0'
gem 'pjax_rails'
gem 'underscore-rails'

gem 'sucker_punch'

ENV['USER_GEMFILE'] ||= './UserGemfile'
eval_gemfile ENV['USER_GEMFILE'] if File.exist?(ENV['USER_GEMFILE'])

gem 'sassc-rails', '~> 2.1.2'
gem 'coffee-rails', '~> 5.0.0'
gem 'js-routes', '~> 2.2.3'
gem 'bootsnap', '~> 1.11.1'
gem 'amazing_print', '~> 1.4.0'
gem 'exception_notification', '~> 4.5.0'