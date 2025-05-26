# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module Tooling
  module Events
    class TrackPipelineEvents
      def initialize(api_token: ENV["CI_INTERNAL_EVENTS_TOKEN"], logger: nil)
        @api_token = api_token
        @logger = logger
      end

      # Send tracking event to usage_data API
      #
      # @param event_name [String] the name of the event to track
      # @param label [String] Event attribute
      # @param value [Number] Numeric event attribute
      # @param property [String] Optional event attribute
      # @return [Net::HTTPResponse]
      def send_event(event_name, label:, value: nil, property: nil)
        return log(:error, "Error: Cannot send event '#{event_name}'. Missing project access token.") unless api_token

        properties = { label:, value:, property: }.compact
        body = {
          event: event_name,
          send_to_snowplow: true,
          namespace_id: namespace_id,
          project_id: project_id,
          additional_properties: properties
        }.to_json

        log(:info, "Sending data for event: #{event_name}")
        response = client.request_post("/api/v4/usage_data/track_event", body, headers)

        if response.code.to_i == 200
          log(:info, "Successfully sent data with properties: #{properties}")
        else
          log(:error, "Failed event tracking: #{response.code}, body: #{response.body}")
        end

        response
      rescue StandardError => e
        log(:error, "Exception when posting event #{event_name}, error: '#{e.message}'")
      end

      private

      attr_reader :api_token, :logger

      # Print to stdout/stderr or use logger if defined
      #
      # @param level [Symbol]
      # @param message [String]
      # @return [void]
      def log(level, message)
        return logger.public_send(level, message) if logger.respond_to?(level) # rubocop:disable GitlabSecurity/PublicSend -- CI usage only

        %i[warn error].include?(level) ? warn(message) : puts(message)
      end

      # Http client
      #
      # @return [Net::HTTP]
      def client
        @client ||= Net::HTTP.new(uri.host, uri.port).tap do |http|
          http.use_ssl = true
        end
      end

      # CI server uri
      #
      # @return [Uri]
      def uri
        @uri ||= URI.parse(ENV['CI_SERVER_URL'])
      end

      # Default request headers
      #
      # @return [Hash]
      def headers
        @headers ||= {
          "PRIVATE-TOKEN" => api_token,
          "Content-Type" => "application/json"
        }
      end

      # Project namespace ID
      #
      # @return [Integer]
      def namespace_id
        @namespace_id ||= ENV["CI_PROJECT_NAMESPACE_ID"].to_i
      end

      # Project ID
      #
      # @return [Integer]
      def project_id
        @project_id ||= ENV["CI_PROJECT_ID"].to_i
      end
    end
  end
end
