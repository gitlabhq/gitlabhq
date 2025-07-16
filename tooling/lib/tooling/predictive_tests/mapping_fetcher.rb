# frozen_string_literal: true

require "httparty"
require "fileutils"
require "tmpdir"
require "open3"
require "logger"
require "json"

require_relative '../test_map_packer'

# rubocop:disable Gitlab/Json, Gitlab/HTTParty -- non-rails
module Tooling
  module PredictiveTests
    class MappingFetcher
      include HTTParty

      PAGES_URL = "https://gitlab-org.gitlab.io/gitlab"
      # Mappings paths correspond to values defined in .gitlab-ci.yml
      # If upload destination is changed, these should be updated
      MAPPINGS = {
        described_class: "crystalball/packed-mapping.json",
        coverage: "crystalball/packed-mapping-alt.json",
        frontend_fixtures: "crystalball/frontend_fixtures_mapping.json"
      }.freeze

      def initialize(timeout: 30, logger: ::Logger.new($stdout))
        @timeout = timeout
        @logger = logger
      end

      def fetch_rspec_mappings(unpacked_mapping_file, type: :described_class)
        logger.info("Downloading spec mappings of type: #{type}")
        FileUtils.mkdir_p(File.dirname(unpacked_mapping_file))

        mapping_file = MAPPINGS.fetch(type.to_sym) do
          logger.warn("No mappings available for type: #{type}, defaulting to described_class")
          MAPPINGS[:described_class]
        end
        # tmpdir ensures all temporary files get deleted
        Dir.mktmpdir("test-mappings") do |dir|
          mapping_file_archive = File.join(dir, "mapping.gz")
          packed_mapping_file = File.join(dir, "mapping.json")

          download("#{PAGES_URL}/#{mapping_file}.gz", mapping_file_archive)
          extract_archive(mapping_file_archive, packed_mapping_file)
          unpack(packed_mapping_file, unpacked_mapping_file)

          unpacked_mapping_file
        end
      end

      def fetch_frontend_fixtures_mappings(file_path)
        logger.info("Downloading frontend fixtures mappings")
        FileUtils.mkdir_p(File.dirname(file_path))

        download("#{PAGES_URL}/#{MAPPINGS[:frontend_fixtures]}", file_path)
        file_path
      end

      private

      attr_reader :timeout, :logger

      def download(url, destination_path)
        logger.debug("Downloading #{url}...")
        response = self.class.get(url, timeout: timeout, stream_body: true) do |fragment|
          File.open(destination_path, 'ab') { |file| file.write(fragment) }
        end
        raise "Download failed with status #{response.code}: #{response.message}" unless response.success?

        logger.debug("Download completed: #{destination_path}")
      end

      def extract_archive(archive, file_path)
        logger.debug("Extracting archive #{archive} to #{file_path}...")
        _out, err, status = Open3.capture3("gzip -d -c #{archive} > #{file_path}")
        raise "Failed to extract archive #{archive}: #{err}" unless status.success?

        logger.debug("Archive extracted to #{file_path}")
      end

      def unpack(packed_mapping, unpacked_mapping)
        packed_mapping = JSON.parse(File.read(packed_mapping))
        mapping = Tooling::TestMapPacker.new.unpack(packed_mapping)

        logger.debug("Writing unpacked #{unpacked_mapping}")
        File.write(unpacked_mapping, JSON.generate(mapping))
        logger.debug("Saved #{unpacked_mapping}")
      end
    end
  end
end
# rubocop:enable Gitlab/Json, Gitlab/HTTParty
