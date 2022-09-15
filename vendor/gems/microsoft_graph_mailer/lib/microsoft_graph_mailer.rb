# frozen_string_literal: true

require_relative "microsoft_graph_mailer/delivery"
require_relative "microsoft_graph_mailer/railtie" if defined?(Rails::Railtie)
require_relative "microsoft_graph_mailer/version"

module MicrosoftGraphMailer
  class Error < StandardError
  end

  class ConfigurationError < Error
  end

  class DeliveryError < Error
  end
end
