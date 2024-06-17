#!/usr/bin/env ruby

require 'bundler/inline'
gemfile do
  source 'https://rubygems.org'
  gem 'thor'
  gem 'rainbow'
  gem 'awesome_print'
  gem 'terminal-table'
  gem 'terminal-emojify'
  gem 'rails'
  gem 'stringio', '~> 3.1.1'
end

require 'tmpdir'
require 'thor'
require 'rainbow'
require 'fileutils'
require 'awesome_print'
require 'bundler'
require 'terminal-table'
require 'terminal/emojify'
require 'active_support/all'
SCRIPT_NAME = File.basename($0)
DS = Time.now.strftime('%F')
class RailsUpgrader < Thor
  include Thor::Actions

  GEM_TARGETS = {
    'rails' => '7.0',
    'skylight' => nil,
    'cancan' => nil,
    'cancancan' => '2.3',
    'paperclip' => nil,
    'protected_attributes' => nil,
    'factory_girl' => nil,
    'factory_girl_rails' => nil,
    'scoped_search' => '4.1',
    'autoprefixer-rails' => '9.5',
    'rainbow' => '3.0',
    'simplecov' => '0.21',
    'mini_racer' => '0.3'
  }.freeze

  DEPRECATED_GEM_MESSAGES = {
    'protected_attributes' => 'Remove gem. Implement strong attributes.',
    'cancan' => 'Switch to cancancan',
    'paperclip' => 'Switch to carrierwave or activestorage.',
    'factory_girl' => 'Switch to factory_bot with `rails-upgrade factory_girl`',
    'factory_girl_rails' => 'Switch to factory_bot_rails',
    'therubyracer' => 'Switch to mini_racer',
    'less-rails' => 'Depends on therubyracer. Use Sass. Use sassc-rails'
  }.freeze


  desc 'overview', 'get a sense of where this project vs. our latest best practices'
  def overview
    #table = Terminal::Table.new
    key_gems = GEM_TARGETS.keys
    #table << %W(gem gemfile lock notes)
    key_gems.each do |gemname|
      target_version = GEM_TARGETS[gemname]
      lock_version = gem_lock_version(gemname)

      status = :not_in_project


      status = if lock_version.nil? && !target_version.nil?
                 # GEM_TARGETS are optional. If the gem is not in the project, no worries.
                 :not_in_project
               elsif target_version.nil? && target_version == lock_version
                 # If the target is nil then we don't want it in the project.
                 # And if the lock_version is nil too then it isn't. Hurray.
                 :not_in_project
               elsif target_version.nil?
                 :needs_removal
               end

      status ||= begin
        target_gv = Gem::Version.new target_version
        lock_gv = Gem::Version.new lock_version
        if lock_gv >= target_gv
          :up_to_date
        else
          :needs_update
        end
      end

      next if status == :not_in_project
      next if status == :up_to_date

      emoji_str = case status
                  when :needs_removal
                    ':no_entry:'
                  when :up_to_date
                    ':white_check_mark:'
                  when :needs_update
                    ':x:'
                  else
                    ':grey_question:'
                  end
      emoji = Terminal::Emojify.call(emoji_str)

      msg = case status
            when :needs_removal
              (DEPRECATED_GEM_MESSAGES[gemname] || 'Remove deprecated gem')
            when :up_to_date
              'Current'
            when :needs_update
              "Upgrade to #{target_version}"
            else
              'Unkown'
            end

      #table << [gemname, gem_version(gemname), lock_version, msg_emoji]
      say "#{emoji} #{gemname}  #{gem_version(gemname)} (#{lock_version}) - #{msg}"
    end

    #say table
    #say
    #say

    #say 'SECURITY'
    #say `bundle-audit`
  end


  desc 'rails5x', 'do the progressive updates from 4.x to 5.x'
  def rails5x
    rails51
    puts "\n\n"
    rails52
  end

  desc 'rails51', 'rails 5.1 upgrades'
  def rails51
    say <<~MSG
      Rails 4.x -> 5.1 Upgrade
      ------------------------
      * https://www.ombulabs.com/blog/rails/upgrades/upgrade-rails-from-4-2-to-5-0.html

    MSG
    gem_deprecate 'inherited_resources', 'Please remove.'

    gem_remove 'sprockets', 'Provided by rails'
    gem_remove 'tilt', 'Provided by rails'
    gem_remove 'protected_attributes', 'UNSUPPORTED. MUST BE REMOVED. Switch to strong attributes. https://github.com/fastruby/rails_upgrader may help', warning: true
    gem_remove 'formtastic', 'UNSUPPORTED. MUST BE REMOVED.', warning: true
    gem_remove 'minitest-rails', 'Abandoned at 4.2'

    gem 'rails', '~> 5.1.0'
    gem 'responders', '~> 2.4.0'
    gem 'jquery-rails', '~> 4.3.1'
    gem 'haml', '~> 5.0'
    gem 'haml-rails', '~> 1.0'

    gem_replace 'cancan', 'cancancan', '~> 2.2'
    gem 'cancancan', '~> 2.2'

    gem_remove 'sass', 'Provided by sass-rails'
    gem_replace 'sass-rails', 'sassc-rails', '~> 2.0'


    gem_upgrade 'activerecord-oracle_enhanced-adapter', '~> 1.8.1'
    gem_upgrade 'activerecord-session_store', '~> 1.1.1'
    gem_upgrade 'bootstrap-sass', '~> 3.3.7'
    gem_upgrade 'exception_notification', '~> 4.2.0'
    gem_upgrade 'kaminari', '~> 1.1.1'
    gem_upgrade 'inherited_resources', '~> 1.8.0'
    gem_upgrade 'formtastic', '~> 3.1.5'
    gem_upgrade 'scoped_search', '~> 4.1.0'
    gem_upgrade 'rainbow', '~> 3.0'

    gem_dev 'listen', '~> 3.1.0'
    gem_dev 'spring-watcher-listen', '~> 2.0.0'


    before_filter_check
    redirect_back_check

    application_record
    removed_configs
    before_filter


    assigns_check
    belongs_to_check
    strong_params_check
    asset_precompile_check

    say '- [ ] Remove config/initializers/quiet_assets.rb' if File.exist?('config/initializers/quiet_assets.rb')
    say '- [ ] run `' + Rainbow('bin/rake app:update').bold + ' to update configs'

  end

  desc 'rails52', 'upgrade rails to 5.2 (you should already be at rails 5.1)'
  def rails52
    say <<~MSG
      Rails 5.1 -> 5.2 Upgrade
      ------------------------
      * https://www.ombulabs.com/blog/rails/upgrades/upgrade-rails-from-5-1-to-5-2.html

    MSG
    #gem_upgrade 'haml-rails', '~> 2.0'
    gem_remove 'haml-rails', 'incompatable with rake 10.4.0'
    gem_remove 'annotations', 'incompatable with rubygems 2.7.6'
    gem_deprecate 'paperclip', 'Please replace with carrierwave or activestorage.'
    gem 'rails', '~> 5.2.0'
    gem_upgrade 'mysql2', '~> 0.5.0'
    gem_upgrade 'ruby-oci8', '~> 2.2.6'
    gem_upgrade 'activerecord-oracle_enhanced-adapter', '~> 5.2.0'
    gem 'sassc-rails', '~> 2.0'
    gem 'coffee-rails', '~> 4.2'
    gem 'js-routes', '~> 1.4.4'
    gem_upgrade 'simplecov', '~> 0.16.1'
    gem_upgrade 'autoprefixer-rails', '~> 7.1.6'
    gem_upgrade 'rainbow', '~> 3.0'
    gem_upgrade 'acts-as-taggable-on', '~> 6.0'
    gem_upgrade 'composite_primary_keys', '~> 11.2'
    gem_upgrade 'web-console', '~> 3.0'
    gem_replace 'therubyracer', 'mini_racer', '~> 0.2.4'
    append_to_file 'Gemfile', "\ngem 'bootsnap', '>= 1.1.0', require: false", verbose: false
    gem_upgrade 'json', '~> 2.2'
    gem_remove 'quiet_assets', 'replaced by framework config'
  end

  desc 'rails7x', 'upgrade to from 6.1 to 7.x'
  def rails7x
    say '- [ ] run `' + Rainbow('bin/rake app:update').bold + ' to update configs'
    say '- [ ] Update config/application.rb to config.load_defaults 7.0'
    rails70
  end

  desc 'rails70', 'upgrade rails to 7.0 (from 6.1)'
  def rails70
    gem 'rails', '~> 7.0.0'
    gem 'exception_notification', '~> 4.5.0'
    gem_remove 'minitest-rails', 'Abandoned w/o rails 7.x pins' # 6.1.0 DOES NOT SUPPORT RAILS 7. A release eventually came, but it was 6mo after, too long.
    gem_upgrade 'amazing_print', '~> 1.4.0'
    gem_upgrade 'bootsnap', '~> 1.11.1'
    gem_upgrade 'font-awesome-sass', '~> 6.1.1'
    gem_upgrade 'js-routes', '~> 2.2.3'
    gem_upgrade 'mini_racer', '~> 0.6.2'
    gem_upgrade 'rainbow', '~> 3.1.1'
    gem_upgrade 'webdrivers', '~> 5.0.0'
  end

  desc 'rails6x', 'upgrade to from 5.2 to 6.x'
  def rails6x
    say '- [ ] run `' + Rainbow('bin/rake app:update').bold + ' to update configs'
    say '- [ ] Update config/application.rb to config.load_defaults 6.1'
    rails60
    rails61
  end

  desc 'rails61', 'upgrade rails to 6.1 (from 6.0)'
  def rails61
    say <<~MSG
      \n\n
      Rails 6.0 -> 6.1 Upgrade
      ------------------------
      * Upgrade guide - https://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html
      * Release Notes - https://edgeguides.rubyonrails.org/6_1_release_notes.html

    MSG

    gem 'rails', '~> 6.1.3'
    gem 'rake', '~> 13.0'
    gem_upgrade 'activerecord-oracle_enhanced-adapter', '~> 6.1.0'
    gem_upgrade 'snoop_dogg', '~> 420.1'
    gem_upgrade 'mysql2', '~> 0.5.3'
    gem_upgrade 'activerecord-session_store', '~> 2.0.0'
    gem_upgrade 'bootsnap', '~> 1.7.0'
    gem_upgrade 'font-awesome-sass', '~> 5.15.1'
    gem_upgrade 'js-routes', '~> 1.4.14'
    gem_upgrade 'jquery-rails', '~> 4.4.0'
    gem_upgrade 'mini_racer', '~> 0.3.1'
    gem_upgrade 'cancancan', '~> 3.2.1'
    gem_upgrade 'scoped_search', '~> 4.1.9'
    gem_upgrade 'rack-attack', '~> 6.3.1'
    gem_upgrade 'exception_notification', '~> 4.4.3'
    gem_upgrade 'foreman', '~> 0.87.2'
    gem_upgrade 'terminal-table', '~> 3.0.0'
    gem_upgrade 'terminal-table', '~> 3.0.0'
    gem_upgrade 'webdrivers', '~> 4.4'
    gem_upgrade 'factory_bot_rails', '~> 6.0'
    gem_upgrade 'ffaker', '~> 2.17'
    gem_upgrade 'minitest-stub_any_instance', '~> 1.0'
    gem_upgrade 'minitest-profile', '~> 0.0'
    gem_upgrade 'simplecov', '~> 0.19'
    gem_upgrade 'rails-controller-testing', '~> 1.0'
    gem_upgrade 'yard', '~> 0.9.26'
    gem_upgrade 'better_errors', '~> 2.8'
    gem_upgrade 'acts-as-taggable-on', '~> 8.0'
    gem_upgrade 'puma', '~> 5.5.0'

    gem 'amazing_print', '~> 1.2.2'
    gem_remove 'awesome_print', 'Replaced by amazing_print'
    sub_file('test/test_helper.rb', 'awesome_print', 'amazing_print')
    gem_remove 'meta_request', 'Causes stack level too deep in Rails 6.1'

    say <<~MSG
      - [ ] Check & update from template:
        - [ ] config/application.rb
        - [ ] config/environments/*
        - [ ] test/test_helper.rb
        - [ ] Rakefile
        - [ ] app/controllers/application_controller.rb
        - [ ] lib/
        - [ ] config/initializers/
      - [ ] If disabling action_cable: rm -rf app/channels app/assets/javascripts/cable.js
    MSG


    if `ag 'form_with' app/**/*.haml 2>/dev/null`.present?
      say "- [ ] from_with has changed to be local by default.\n\tIf you want it to be remote, add `local: false`."
    end

    unless gemfile_contains?('jsnlog')
      say <<~MSG
        - [ ] If you added jsnlog gem
          - gem 'jsnlog', '~> 2.30' # not a typo "two dot thirty"
          - bin/rails g jsnlog:install # appends to application.js & config/routes
      MSG
    end


    unless File.exist?('bin/spring')
      say <<~MSG
        - [ ] If you removed spring
          - [ ] remove spring requires from bin/rake & bin/rails
          - [ ] rm bin/spring
      MSG
    end

    if gemfile_contains?('responders')
      say '- [ ] remove responders if no respond_with, lines from application controller, and:'
      say '  - [ ] rm -f config/initializers/application_controller_renderer.rb lib/application_responder.rb'
    end

  end

  desc 'rails60', 'upgrade rails to 6.0 (you should already be at rails 5.2)'
  def rails60
    say <<~MSG
      \n\n
       Rails 5.x -> 6.0 Upgrade
       ------------------------
       * Upgrade guide - https://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html
       * Release Notes - https://edgeguides.rubyonrails.org/6_0_release_notes.html

    MSG
    gem 'rails', '~> 6.0.2'
    #gem_upgrade 'webpacker', '~> 4.0'
    say "- Intentionally not adding gem 'webpacker', '~> 4.x'"
    gem_upgrade 'nokogiri', '~> 1.10.7'
    gem_upgrade 'coffee-rails', '~> 5.0.0'
    gem_upgrade 'sqlite3', '~> 1.4.0'
    gem_upgrade 'jbuilder', '~> 2.9.0'
    gem_upgrade 'bootsnap', '~> 1.4.6'
    gem_upgrade 'activerecord-oracle_enhanced-adapter', '~> 6.0.0'
    gem_upgrade 'mime-types', '~> 3.2.2'
    gem_upgrade 'responders', '~> 3.0.0'
    gem_upgrade 'skylight', '~> 4.2.1'
    gem_upgrade 'cancancan', '~> 3.0.0'
    gem_upgrade 'haml', '~> 5.1.2'
    gem_upgrade 'haml-rails', '~> 2.0.1'
    gem_upgrade 'font-awesome-sass', '~> 5.12.0'
    gem_upgrade 'exception_notification', '~> 4.4.0'
    gem_remove 'sprockets', 'unpin sprockets' # we get the 4.0 as a dep, so remove in case we're pinned lower
    gem_upgrade 'minitest-rails', '~> 6.0'
    gem_remove 'sass-rails', 'removing sass-rails to add sassc-rails'
    gem 'sassc-rails', '~> 2.1.2'
    gem_remove 'therubyracer', 'switch to mini_racer'
    gem 'mini_racer', '~> 0.2.8'

    gem_remove 'chromedriver-helper', "replaced with 'webdrivers'"
    gem_dev 'webdrivers', '~> 4.0'

    if `ag 'autoload_paths.*models/\*\*' config/application.rb 2>/dev/null`.present?
      say "- [ ] You must fix the autoload_paths removing any globbing ('**') and only including folders that are themselves not part of a namespace. e.g. models/lawson should not be included because it contains Lawson::Whatever classes. `concerns` may be included because we load the files as 'WhateverConcern' (not namespaced by the concern folder). This is to accomodate the new Zeitwerk autoloader in rails 6.0. In most cases you can just remove the models/** line, but you should check for other exotic models/ subfolders."
    end

    if `ag 'cookie_serializer = :marshal' config/initializers/cookies_serializer.rb 2>/dev/null`.present?
      say "- [ ] change cookie_serializer to :hybrid in config/initializers/cookies_serializer.rb\n\tthe rake app:update is going to change it to :json, and that will break all the existing cookies"
    end

    if `ag 'form_with' app/**/*.haml 2>/dev/null`.present?
      say '- [ ] Check all form_with calls. They switch to remote by default in rails 6. Add `local: true` to make them non-remote.'
    end

    # add manifest.js for sprockets 4
    manifestjs


    unless `ag config.hosts.clear config/environments/development.rb`.present?
      say "- [ ] add this to config/environments/development.rb\n  config.hosts.clear # no dns safelist, allow all"
    end

    if `ag 'Rails.application.config.active_record.belongs_to_required_by_default = false'`.present?
      say "- [ ] config.active_record.belongs_to_required_by_default is not longer supported. Add 'optional: true' on EACH belongs_to that should be optional. Otherwise it will trigger presence validation."
    end

  end

  desc 'ruby3', 'upgrade assorted ruby3 impacted gems'
  def ruby3
    gem_upgrade 'prawn', '~> 2.4.0'
    gem_upgrade 'bootsnap', '~> 1.9.3'
    gem_upgrade 'binding_of_caller', '~> 1.0.0'
    gem_upgrade 'listen', '~> 3.7.0'
  end

  desc 'apple_touch', 'add blank apple-touch icons'
  def apple_touch
    filenames = %w[
      apple-touch-icon-120x120.png
      apple-touch-icon-120x120-precomposed.png
      apple-touch-icon.png
      apple-touch-icon-precomposed.png
      apple-touch-icon-152x152.png
      apple-touch-icon-152x152-precomposed.png
    ]
    filenames.each do |filename|
      FileUtils.touch "public/#{filename}"
    end
  end

  desc 'factory_girl', 'upgrade factory_girl to factory_bot'
  def factory_girl
    `rpl factory_girl factory_bot **/*.rb`
    `rpl FactoryGirl FactoryBot **/*.rb`
    `rpl factory_girl factory_bot Gemfile`
    gem 'factory_bot', '~> 4.10'
  end

  desc 'application_record', 'adds ApplicationRecord and replaces all references to ActiveRecord::Base with it'
  def application_record
    say '- [x] Add ApplicationRecord abstract model'
    create_file 'app/models/application_record.rb', <<~FILE
      class ApplicationRecord < ActiveRecord::Base
        self.abstract_class = true
      end
    FILE

    say '- [x] Make all models descend from ApplicationRecord'
    Dir['app/models/**/*.rb'].each do |file|
      next if File.basename(file) == 'application_record.rb'
      gsub_file file, /ActiveRecord::Base/, 'ApplicationRecord', verbose: false
    end

  end

  desc 'before_filter', 'change before_filter to before_action in controllers'
  def before_filter
    Dir['app/controllers/**/*.rb'].each do |file|
      gsub_file file, / before_filter :/, ' before_action :', verbose: false
    end
  end

  desc 'removed_configs', 'checks for invalid values in config/'
  def removed_configs
    gsub_file 'config/application.rb', /(\s*)(config.active_record.raise_in_transactional_callbacks.*)$/, "\\1#\\2 # Removed by #{SCRIPT_NAME} #{DS}", verbose: false
    gsub_file 'config/environments/development.rb', /(\s*)(config.active_record.mass_assignment_sanitizer.*)$/, "\\1#\\2 # Removed by #{SCRIPT_NAME} #{DS}", verbose: false
    gsub_file 'config/environments/test.rb', /(\s*)(config.active_record.mass_assignment_sanitizer.*)$/, "\\1#\\2 # Removed by #{SCRIPT_NAME} #{DS}", verbose: false
  end

  desc 'protected_attributes_check', 'check for attr_accessible'
  def protected_attributes_check
    out = `ag attr_accessible config/**/*.rb config/*.rb`
    if $?.success?
      say "- [ ] You must remove all attr_accessible calls, and ensure that the model's controller has strong params model_params setup."
      say out
    end
  end

  desc 'belongs_to_check', 'belongs_to is now required by default. optional: true can be added. all should be checked'
  def belongs_to_check
    results = `ag belongs_to app/models/*.rb 2>/dev/null`
    results << `ag belongs_to app/models/**/*.rb 2>/dev/null`
    if results.present?
      say '- [ ] belongs_to is now required by default. optional: true can be added. all should be checked'
      say `pwd`.indent(4)
      say results.lines.map{|line| '[ ] ' + line}.join.indent(8)
    end
  end

  desc 'strong_params_check', 'strong_params is required. protected_attributes must be removed.'
  def strong_params_check
    results = `ag attr_accessible app/models/*.rb 2>/dev/null`
    results += `ag attr_accessible app/models/**/*.rb 2>/dev/null`
    if results.present?
      say '- [ ] attr_accessible must be removed. Switch to strong params! remove protected_attributes gem'
      say `pwd`.indent(4)
      say results.lines.map{|line| '- [ ] ' + line}.join.indent(8)
    end
  end

  desc 'asset_precompile_check', 'look for assets that need to be added to the assets initializer precompile list'
  def asset_precompile_check
    result = `egrep -s '(link_tag|include_tag)' app/views/*/* | cut -d= -f2 | cut -d, -f1 | grep -v "['\\"]application['\\"]" | sort -u`
    if result.present?
      say '- [ ] precomplie assets - The following files need to be added to the precompile in config/initializers/assets.rb:'
      say `pwd`.indent(4)
      say result.lines.map{|line| '- [ ] ' + line}.join.indent(8)
    end
  end

  desc 'assigns_check', 'the assigns method has been extracted to a gem, check if it is used, and add the gem'
  def assigns_check
    `grep assigns test/**/*.rb`
    if $?.success?
      say "- [x] Detected 'assigns' testing method is in used. Adding extracted gem \"gem 'rails-controller-testing'\""
      append_to_file 'Gemfile', "\ngem 'rails-controller-testing'", verbose: false
    end
  end

  desc 'redirect_back_check', "'redirect_to :back' has been deprecated, use 'redirect_back fallback_location: url' instead."
  def redirect_back_check
    results = `ag 'redirect_to :back'`
    if $?.success?
      warn "Use of 'redirect_to :back'. Replace with 'redirect_back fallback_location: url'"
      say results.indent(4)
    end
  end

  desc 'before_filter_check', "'before_filter' has been deprecated, use 'before_action' instead."
  def before_filter_check
    results = `ag 'before_filter' **/*.rb`
    if $?.success?
      warn "Use of 'before_filter'. Replace with 'before_action'"
      say results.indent(4)
    end
  end

  desc 'gitlab_ci', 'upgrade .gitlab-ci.yml file from template'
  def gitlab_ci
    FileUtils.cp File.expand_path('./templates/gitlab-ci-remote-link.yml', __dir__), '.gitlab-ci.yml'
    say `git diff .gitlab-ci.yml`
  end

  desc 'static_semantic_ui', 'upgrade static semantic_ui files'
  def static_semantic_ui
    semantic_ui_release_url = 'https://github.com/Semantic-Org/Semantic-UI-CSS/archive/master.tar.gz'
    gem_remove 'less-rails-semantic_ui', 'Switching from less-rails-semantic_ui to static assets'
    pwd = `pwd`.strip
    Dir.mktmpdir do |dir|
      Dir.chdir dir
      say "Downloading #{semantic_ui_release_url} to #{dir}"
      `wget -q #{semantic_ui_release_url}`

      say "Extracting tar in #{dir}"
      `tar xf master.tar.gz`

      say 'Moving themes folder'
      FileUtils.mv "#{dir}/Semantic-UI-CSS-master/themes", "#{pwd}/app/assets/stylesheets/", force: true

      say 'Moving css file'
      FileUtils.mv "#{dir}/Semantic-UI-CSS-master/semantic.min.css", "#{pwd}/app/assets/stylesheets/"

      say 'Moving js file'
      FileUtils.mv "#{dir}/Semantic-UI-CSS-master/semantic.min.js", "#{pwd}/app/assets/javascripts/"

      say 'Done'
      Dir.chdir pwd
      say
      say `git status -s`
      say
      say <<~MSG
        You'll still need to update your css/js includes:

          application.js:
            //= require semantic.min

          application.css:
            *= require semantic.min
      MSG
    end
  end


  desc 'manifestjs', 'add manifest.js for sprockets 4'
  def manifestjs
    unless File.exist?('app/assets/config/manifest.js')
      `mkdir app/assets/config || true`
      IO.write('app/assets/config/manifest.js', <<~CONTENT)
        //= link_tree ../images
        //= link_directory ../javascripts .js
        //= link_directory ../stylesheets .css
      CONTENT
      say '- [x] added app/assets/config/manifest.js for sprockets 4'
    end
  end

  private

  def gem(gem_name, version_condition)
    _ = `grep "gem ['\\"]#{gem_name}" Gemfile`
    if $?.success?
      gem_upgrade gem_name, version_condition
    else
      append_to_file 'Gemfile', "\ngem '#{gem_name}', '#{version_condition}'", verbose: false
    end
  end

  # only upgrade it if it's already in the file
  def gem_upgrade(gem_name, version_condition)
    gsub_file 'Gemfile', /(?!#)gem ['\\"]#{gem_name}['\\"].*$/, "gem '#{gem_name}', '#{version_condition}'", verbose: false
  end

  # only upgrade it if it's already in the file
  def gem_replace(gem_name, new_gem_name, version_condition)
    gsub_file 'Gemfile', /(?!#)gem ['\\"]#{gem_name}['\\"].*$/, "gem '#{new_gem_name}', '#{version_condition}'", verbose: false
  end

  def gem_dev(gem_name, version_condition)
    _ = `grep "gem ['\\"]#{gem_name}" Gemfile`
    if $?.success?
      gem gem_name, version_condition
    else
      sub_file 'Gemfile', /(group.*:development.*)/, "\\1\n  gem '#{gem_name}', '#{version_condition}'"
    end
  end

  def gem_remove(gem_name, message, warning: false)
    _ = `ag #{gem_name} Gemfile`
    if $?.success?
      if warning
        say '- [ ] Removed gem ' + Rainbow(gem_name).red + ". ACTION REQUIRED. #{message}"
      else
        say '- [x] Removed gem ' + Rainbow(gem_name).white + ". #{message}"
      end

      gsub_file 'Gemfile', /^(\s*(?!#)\s*)(gem ['\\"]#{gem_name}['\\"].*)$/, "\\1# \\2 # Removed by #{SCRIPT_NAME} #{DS}", verbose: false
    end
  end

  def gem_deprecate(gem_name, message)
    warn 'Deprecated gem ' + Rainbow(gem_name).red + ' ' + message if gemfile_contains?(gem_name)
  end

  def gemfile_contains?(string_pattern)
    file_contains?('Gemfile', string_pattern)
  end

  def file_contains?(filename, string_pattern)
    File.read(filename).include? string_pattern
  end

  def gem_version(name)
    parsed = Bundler::LockfileParser.new(Bundler.read_file(Bundler.default_lockfile))
    parsed.dependencies[name].requirement.to_s rescue nil
  end

  def gem_lock_version(name)
    parsed = Bundler::LockfileParser.new(Bundler.read_file(Bundler.default_lockfile))
    parsed.specs.select{|spec| spec.name == name}.first.version.to_s rescue nil
  end

  def sub_file(relative_file, search_text, replace_text)
    file_content = File.read(relative_file)
    content = file_content.sub(search_text, replace_text)
    File.open(relative_file, 'wb') { |file| file.write(content) }
  end
end

RailsUpgrader.start(ARGV)