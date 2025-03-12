# frozen_string_literal: true
require 'rails/generators'
require 'rails/generators/base'
require_relative 'core'
require_relative 'relay'

module Graphql
  module Generators
    class RelayGenerator < Rails::Generators::Base
      include Core
      include Relay

      desc "Add base types and fields for Relay-style nodes and connections"
      source_root File.expand_path('../templates', __FILE__)

      def install_relay
        super
      end
    end
  end
end
