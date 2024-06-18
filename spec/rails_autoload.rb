# frozen_string_literal: true

# Mimics Rails autoloading with zeitwerk when used outside of Rails.
# This is used in:
# * fast_spec_helper
# * scripts/setup-test-env

require 'zeitwerk'
require 'active_support/string_inquirer'

module Rails
  extend self

  def root
    Pathname.new(File.expand_path('..', __dir__))
  end

  def env
    @_env ||= ActiveSupport::StringInquirer.new(ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "test")
  end

  def autoloaders
    @autoloaders ||= [
      Zeitwerk::Loader.new.tap do |loader|
        loader.inflector = _autoloader_inflector
      end
    ]
  end

  private

  def _autoloader_inflector
    # Try Rails 7 first.
    require 'rails/autoloaders/inflector'

    Rails::Autoloaders::Inflector
  rescue LoadError
    # Fallback to Rails 6.
    require 'active_support/dependencies'
    require 'active_support/dependencies/zeitwerk_integration'

    ActiveSupport::Dependencies::ZeitwerkIntegration::Inflector
  end
end

require_relative '../lib/gitlab'
require_relative '../config/initializers/0_inject_enterprise_edition_module'
require_relative '../config/initializers_before_autoloader/000_inflections'
require_relative '../config/initializers_before_autoloader/004_zeitwerk'

# We wrap this bit of logic in a module to avoid polluting the global namespace with a local variable and methods
module AutoloadersSetup
  def self.dir_already_autoloaded?(autoloaded_dirs, dir)
    autoloaded_dirs.any?(File.expand_path(dir, __dir__))
  end

  def self.setup_autoloaders
    autoloaded_dirs = [] # NOTE: can't use Rails.autoloaders.each_with_object, it doesn't work, so we need a local var.
    Rails.autoloaders.each do |autoloader|
      autoloader.push_dir('lib') unless dir_already_autoloaded?(autoloaded_dirs, "../lib")
      autoloader.push_dir('ee/lib') if Gitlab.ee? && !dir_already_autoloaded?(autoloaded_dirs, "../ee/lib")
      autoloader.push_dir('jh/lib') if Gitlab.jh? && !dir_already_autoloaded?(autoloaded_dirs, "../jh/lib")
      autoloader.setup
      autoloaded_dirs += autoloader.dirs
    end
  end
end

AutoloadersSetup.setup_autoloaders
