# frozen_string_literal: true

require 'json'
require 'time'
require_relative '../../../lib/gitlab/popen' unless defined?(Gitlab::Popen)

module Tooling
  class KubernetesClient
    K8S_ALLOWED_NAMESPACES_REGEX = /^review-(?!apps).+/.freeze
    CommandFailedError           = Class.new(StandardError)

    def cleanup_pvcs_by_created_at(created_before:)
      stale_pvcs = pvcs_created_before(created_before: created_before)

      # `kubectl` doesn't allow us to filter namespaces with a regexp. We therefore do the filtering in Ruby.
      review_apps_stale_pvcs = stale_pvcs.select do |stale_pvc_hash|
        K8S_ALLOWED_NAMESPACES_REGEX.match?(stale_pvc_hash[:namespace])
      end
      return if review_apps_stale_pvcs.empty?

      review_apps_stale_pvcs.each do |pvc_hash|
        delete_pvc(pvc_hash[:resource_name], pvc_hash[:namespace])
      end
    end

    def cleanup_namespaces_by_created_at(created_before:)
      stale_namespaces = namespaces_created_before(created_before: created_before)

      # `kubectl` doesn't allow us to filter namespaces with a regexp. We therefore do the filtering in Ruby.
      review_apps_stale_namespaces = stale_namespaces.select { |ns| K8S_ALLOWED_NAMESPACES_REGEX.match?(ns) }
      return if review_apps_stale_namespaces.empty?

      delete_namespaces(review_apps_stale_namespaces)
    end

    def delete_pvc(pvc, namespace)
      return unless K8S_ALLOWED_NAMESPACES_REGEX.match?(namespace)

      run_command("kubectl delete pvc --namespace=#{namespace} --now --ignore-not-found #{pvc}")
    end

    def delete_namespaces(namespaces)
      return if namespaces.any? { |ns| !K8S_ALLOWED_NAMESPACES_REGEX.match?(ns) }

      run_command("kubectl delete namespace --now --ignore-not-found #{namespaces.join(' ')}")
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

    def pvcs_created_before(created_before:)
      resource_created_before(resource_type: 'pvc', created_before: created_before) do |item|
        {
          resource_name: item.dig('metadata', 'name'),
          namespace: item.dig('metadata', 'namespace')
        }
      end
    end

    def namespaces_created_before(created_before:)
      resource_created_before(resource_type: 'namespace', created_before: created_before) do |item|
        item.dig('metadata', 'name')
      end
    end

    def resource_created_before(resource_type:, created_before:)
      response = run_command("kubectl get #{resource_type} --all-namespaces --sort-by='{.metadata.creationTimestamp}' -o json")

      items = JSON.parse(response)['items'] # rubocop:disable Gitlab/Json
      items.filter_map do |item|
        item_created_at = Time.parse(item.dig('metadata', 'creationTimestamp'))

        yield item if item_created_at < created_before
      end
    rescue ::JSON::ParserError => ex
      puts "Ignoring this JSON parsing error: #{ex}\n\nResponse was:\n#{response}"
      []
    end

    def run_command(command)
      puts "Running command: `#{command}`"

      result = Gitlab::Popen.popen_with_detail([command])

      if result.status.success?
        result.stdout.chomp.freeze
      else
        raise CommandFailedError, "The `#{command}` command failed (status: #{result.status}) with the following error:\n#{result.stderr}"
      end
    end
  end
end
