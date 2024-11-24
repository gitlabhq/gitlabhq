# frozen_string_literal: true

module Doorkeeper
  module OpenidConnect
    class InstallGenerator < ::Rails::Generators::Base
      include ::Rails::Generators::Migration
      source_root File.expand_path('templates', __dir__)
      desc 'Installs Doorkeeper OpenID Connect.'

      def install
        template 'initializer.rb', 'config/initializers/doorkeeper_openid_connect.rb'
        copy_file File.expand_path('../../../../config/locales/en.yml', __dir__), 'config/locales/doorkeeper_openid_connect.en.yml'
        route 'use_doorkeeper_openid_connect'
      end
    end
  end
end
