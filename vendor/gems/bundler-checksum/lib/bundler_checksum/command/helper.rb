# frozen_string_literal: true

require 'json'
require 'net/http'

module BundlerChecksum::Command
  module Helper
    extend self

    def remote_checksums_for_gem(gem_name, gem_version)
      response = Net::HTTP.get_response(URI(
        "https://rubygems.org/api/v1/versions/#{gem_name}.json"
      ))

      return [] unless response.code == '200'

      gem_candidates = JSON.parse(response.body, symbolize_names: true)
      gem_candidates.select! { |g| g[:number] == gem_version.to_s }

      gem_candidates.map {
        |g| {:name => gem_name, :version => gem_version, :platform => g[:platform], :checksum => g[:sha]}
      }

    rescue JSON::ParserError
      []
    end
  end
end
