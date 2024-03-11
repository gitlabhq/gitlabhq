# frozen_string_literal: true

require 'json'
require 'time'
require_relative '../../../lib/gitlab/popen' unless defined?(Gitlab::Popen)

module Tooling
  class KubernetesClient
    K8S_ALLOWED_NAMESPACES_REGEX = /^review-(?!apps).+/
    CommandFailedError           = Class.new(StandardError)

    def cleanup_namespaces_by_created_at(created_before:)
      stale_namespaces = namespaces_created_before(created_before: created_before)

      # `kubectl` doesn't allow us to filter namespaces with a regexp. We therefore do the filtering in Ruby.
      review_apps_stale_namespaces = stale_namespaces.select { |ns| K8S_ALLOWED_NAMESPACES_REGEX.match?(ns) }
      return if review_apps_stale_namespaces.empty?

      delete_namespaces(review_apps_stale_namespaces)
    end

    def delete_namespaces(namespaces)
      return if namespaces.any? { |ns| !K8S_ALLOWED_NAMESPACES_REGEX.match?(ns) }

      run_command(%W[kubectl delete namespace --now --ignore-not-found #{namespaces.join(' ')}])
    end

    def delete_namespaces_by_exact_names(resource_names:, wait:)
      command = [
        'delete',
        'namespace',
        '--now',
        '--ignore-not-found',
        %(--wait=#{wait}),
        resource_names.join(' ')
      ]

      run_command(command)
    end

    def namespaces_created_before(created_before:)
      command = [
        'kubectl',
        'get',
        'namespace',
        '--all-namespaces',
        '--sort-by',
        '{.metadata.creationTimestamp}',
        '-o',
        'json'
      ]

      response = run_command(command)

      items = JSON.parse(response)['items'] # rubocop:disable Gitlab/Json
      items.filter_map do |item|
        item_created_at = Time.parse(item.dig('metadata', 'creationTimestamp'))

        item.dig('metadata', 'name') if item_created_at < created_before
      end
    rescue ::JSON::ParserError => ex
      puts "Ignoring this JSON parsing error: #{ex}\n\nResponse was:\n#{response}"
      []
    end

    def run_command(command)
      command_str = command.join(' ')
      puts "Running command: `#{command_str}`"

      result = Gitlab::Popen.popen_with_detail(command)

      if result.status.success?
        result.stdout.chomp.freeze
      else
        raise CommandFailedError, "The `#{command_str}` command failed (status: #{result.status}) with the following error:\n#{result.stderr}"
      end
    end
  end
end
