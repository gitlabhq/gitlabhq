# frozen_string_literal: true

module Doorkeeper
  module OpenidConnect
    class UserinfoController < ::Doorkeeper::ApplicationMetalController
      before_action -> { doorkeeper_authorize! :openid }

      def show
        render json: Doorkeeper::OpenidConnect::UserInfo.new(doorkeeper_token), status: :ok
      end
    end
  end
end
