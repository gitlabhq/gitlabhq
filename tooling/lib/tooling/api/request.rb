# frozen_string_literal: true

require 'rails'
require 'net/http'
require_relative '../../../../lib/gitlab/utils/link_header_parser'

module Tooling
  module API
    class Request
      class << self
        # Pass a block to this method to be called with each page of results.
        def get(api_token, uri)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true

          request = Net::HTTP::Get.new(uri)
          request['PRIVATE-TOKEN'] = api_token

          response = http.request(request)

          return response unless block_given?

          # Yield the first page of results, and then yield successive pages.
          yield response

          # Continue to loop over pages until there are no more.
          next_page_url = get_next_page_url(response)
          while next_page_url
            uri = URI(next_page_url)
            response = get(api_token, uri)

            yield response

            next_page_url = get_next_page_url(response)
          end
        end

        private

        def get_next_page_url(response)
          link_header = response['Link']
          parsed = Gitlab::Utils::LinkHeaderParser.new(link_header).parse

          parsed.dig(:next, :uri)
        end
      end
    end
  end
end
