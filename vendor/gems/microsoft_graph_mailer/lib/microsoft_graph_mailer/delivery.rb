# frozen_string_literal: true

require_relative "client"

module MicrosoftGraphMailer
  class Delivery
    attr_reader :microsoft_graph_settings

    def initialize(microsoft_graph_settings)
      @microsoft_graph_settings = microsoft_graph_settings

      [:user_id, :tenant, :client_id, :client_secret].each do |setting|
        unless microsoft_graph_settings[setting]
          raise MicrosoftGraphMailer::ConfigurationError, "'#{setting}' is missing"
        end
      end

      @microsoft_graph_settings[:azure_ad_endpoint] ||= "https://login.microsoftonline.com"
      @microsoft_graph_settings[:graph_endpoint] ||= "https://graph.microsoft.com"
    end

    def deliver!(message)
      # https://github.com/mikel/mail/pull/872
      if message[:bcc]
        previous_message_bcc_include_in_headers = message[:bcc].include_in_headers
        message[:bcc].include_in_headers = true
      end

      message_in_mime_format = message.encoded

      client = MicrosoftGraphMailer::Client.new(
        user_id: microsoft_graph_settings[:user_id],
        tenant: microsoft_graph_settings[:tenant],
        client_id: microsoft_graph_settings[:client_id],
        client_secret: microsoft_graph_settings[:client_secret],
        azure_ad_endpoint: microsoft_graph_settings[:azure_ad_endpoint],
        graph_endpoint: microsoft_graph_settings[:graph_endpoint]
      )

      response = client.send_mail(message_in_mime_format)

      raise MicrosoftGraphMailer::DeliveryError unless response.status == 202

      response
    ensure
      message[:bcc].include_in_headers = previous_message_bcc_include_in_headers if message[:bcc]
    end
  end
end
