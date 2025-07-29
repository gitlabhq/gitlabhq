# frozen_string_literal: true

require 'net/http'

module Tooling
  module CiAnalytics
    class JobTraceDownloader
      def initialize(api_url:, token:, project_id:)
        @api_url = api_url
        @token = token
        @project_id = project_id
      end

      def download_job_trace(job_id)
        uri = URI("#{@api_url}/projects/#{@project_id}/jobs/#{job_id}/trace")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Get.new(uri)
        request['PRIVATE-TOKEN'] = @token

        response = http.request(request)

        if response.code == '200'
          size_kb = (response.body.length / 1024.0).round(1)
          puts "✅ Downloaded job trace (#{size_kb} KB)"
          response.body
        else
          puts "❌ Failed to download trace: #{response.code}"
          nil
        end
      end
    end
  end
end
