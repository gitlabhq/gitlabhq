# frozen_string_literal: true

module Tooling
  module Events
    class TrackPipelineEvents
      API_ENDPOINT = "#{ENV['CI_API_V4_URL']}/usage_data/track_event".freeze
      NAMESPACE_ID = 9970 # gitlab-org group
      PROJECT_ID = 278964 # gitlab-org/gitlab project

      # Initializes a new event tracker
      #
      # @param [String] event_name The name of the event to track
      # @param [Hash] properties A hash of properties to include with the event
      #   @option properties [String] :label String Event attribute
      #   @option properties [Integer] :value Numeric Event attribute
      #   @option properties [String] :property Another String attribute
      # @param [Hash] args Additional arguments to pass to the parent class
      def initialize(event_name:, properties: {}, **args)
        @event_name = event_name
        @properties = properties
        @args = args
        @api_token = ENV["CI_INTERNAL_EVENTS_TOKEN"]
      end

      def send_event
        unless api_token
          puts "ERROR: Cannot send event '#{event_name}'. Missing project access token."
          return
        end

        uri = URI.parse(API_ENDPOINT)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri.path)
        request.body = request_body.to_json
        headers.each { |key, value| request[key] = value }

        response = http.request(request)

        if response.code.to_i == 200
          puts "Successfully sent data for event: #{event_name}"
        else
          puts "Failed event tracking: #{response.code}, body: #{response.body}"
        end

        response
      end

      private

      attr_reader :event_name, :properties, :args, :api_token

      def headers
        {
          "PRIVATE-TOKEN" => api_token,
          "Content-Type" => "application/json"
        }
      end

      def request_body
        {
          event: event_name,
          send_to_snowplow: true,
          namespace_id: NAMESPACE_ID,
          project_id: PROJECT_ID,
          additional_properties: properties
        }
      end
    end
  end
end
