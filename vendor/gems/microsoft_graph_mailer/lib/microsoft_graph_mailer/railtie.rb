# frozen_string_literal: true

require_relative "delivery"

module MicrosoftGraphMailer
  class Railtie < Rails::Railtie
    ActiveSupport.on_load(:action_mailer) do
      add_delivery_method :microsoft_graph, MicrosoftGraphMailer::Delivery
    end
  end
end
