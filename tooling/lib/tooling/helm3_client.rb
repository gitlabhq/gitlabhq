# frozen_string_literal: true

require 'time'
require 'json'
require_relative '../../../lib/gitlab/popen' unless defined?(Gitlab::Popen)

module Tooling
  class Helm3Client
    CommandFailedError = Class.new(StandardError)

    RELEASE_JSON_ATTRIBUTES = %w[name revision updated status chart app_version namespace].freeze
    PAGINATION_SIZE = 256 # Default helm list pagination size

    Release = Struct.new(:name, :namespace, :revision, :updated, :status, :chart, :app_version, keyword_init: true) do
      def revision
        @revision ||= self[:revision].to_i
      end

      def last_update
        @last_update ||= self[:updated] ? Time.parse(self[:updated]) : nil
      end
    end

    # A single page of data and the corresponding page number.
    Page = Struct.new(:releases, :number)

    def releases(args: [])
      each_release(args)
    end

    def delete(release_name:, namespace: nil)
      release_name = Array(release_name)

      release_name.each do |release|
        run_command(['uninstall', '--namespace', (namespace || release), release])
      end
    end

    private

    def run_command(command)
      final_command = ['helm', *command]
      final_command_str = final_command.join(' ')
      puts "Running command: `#{final_command_str}`"

      result = Gitlab::Popen.popen_with_detail(final_command)

      if result.status.success?
        result.stdout.chomp.freeze
      else
        raise CommandFailedError, "The `#{final_command_str}` command failed (status: #{result.status}) with the following error:\n#{result.stderr}"
      end
    end

    def raw_releases(page, args = [])
      command = [
        'list',
        '--max',
        PAGINATION_SIZE.to_s,
        '--offset',
        (PAGINATION_SIZE * page).to_s,
        '--output',
        'json',
        *args
      ]

      response = run_command(command)
      releases = JSON.parse(response) # rubocop:disable Gitlab/Json

      releases.map do |release|
        Release.new(release.slice(*RELEASE_JSON_ATTRIBUTES))
      end
    rescue ::JSON::ParserError => ex
      puts "Ignoring this JSON parsing error: #{ex}\n\nResponse was:\n#{response}"
      []
    end

    # Fetches data from Helm and yields a Page object for every page
    # of data, without loading all of them into memory.
    #
    # method - The Octokit method to use for getting the data.
    # args - Arguments to pass to the `helm list` command.
    def each_releases_page(args, &block)
      return to_enum(__method__, args) unless block

      page = 0
      final_args = args.dup

      begin
        collection = raw_releases(page, final_args)

        yield Page.new(collection, page += 1)
      end while collection.any?
    end

    # Iterates over all of the releases.
    #
    # args - Any arguments to pass to the `helm list` command.
    def each_release(args, &block)
      return to_enum(__method__, args) unless block

      each_releases_page(args) do |page|
        page.releases.each do |release|
          yield release
        end
      end
    end
  end
end
