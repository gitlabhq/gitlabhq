# frozen_string_literal: true

module Doorkeeper
  module OpenidConnect
    class Engine < ::Rails::Engine
      initializer 'doorkeeper.openid_connect.routes' do
        Doorkeeper::OpenidConnect::Rails::Routes.install!
      end

      config.to_prepare do
        Doorkeeper::AuthorizationsController.prepend Doorkeeper::OpenidConnect::AuthorizationsExtension
      end
    end
  end
end
