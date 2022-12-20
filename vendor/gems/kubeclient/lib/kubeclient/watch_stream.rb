require 'json'
require 'http'
module Kubeclient
  module Common
    # HTTP Stream used to watch changes on entities
    class WatchStream
      def initialize(uri, http_options, formatter:)
        @uri = uri
        @http_client = nil
        @http_options = http_options
        @http_options[:http_max_redirects] ||= Kubeclient::Client::DEFAULT_HTTP_MAX_REDIRECTS
        @formatter = formatter
      end

      def each
        @finished = false

        @http_client = build_client
        response = @http_client.request(:get, @uri, build_client_options)
        unless response.code < 300
          raise Kubeclient::HttpError.new(response.code, response.reason, response)
        end

        buffer = ''
        response.body.each do |chunk|
          buffer << chunk
          while (line = buffer.slice!(/.+\n/))
            yield @formatter.call(line.chomp)
          end
        end
      rescue StandardError
        raise unless @finished
      end

      def finish
        @finished = true
        @http_client.close unless @http_client.nil?
      end

      private

      def max_hops
        @http_options[:http_max_redirects] + 1
      end

      def follow_option
        if max_hops > 1
          { max_hops: max_hops }
        else
          # i.e. Do not follow redirects as we have set http_max_redirects to 0
          # Setting `{ max_hops: 1 }` does not work FWIW
          false
        end
      end

      def build_client
        client = HTTP::Client.new(follow: follow_option)

        if @http_options[:basic_auth_user] && @http_options[:basic_auth_password]
          client = client.basic_auth(
            user: @http_options[:basic_auth_user],
            pass: @http_options[:basic_auth_password]
          )
        end

        client
      end

      def using_proxy
        proxy = @http_options[:http_proxy_uri]
        return nil unless proxy
        p_uri = URI.parse(proxy)
        {
          proxy_address: p_uri.hostname,
          proxy_port: p_uri.port,
          proxy_username: p_uri.user,
          proxy_password: p_uri.password
        }
      end

      def build_client_options
        client_options = {
          headers: @http_options[:headers],
          proxy: using_proxy
        }
        if @http_options[:ssl]
          client_options[:ssl] = @http_options[:ssl]
          socket_option = :ssl_socket_class
        else
          socket_option = :socket_class
        end
        client_options[socket_option] = @http_options[socket_option] if @http_options[socket_option]
        client_options
      end
    end
  end
end
