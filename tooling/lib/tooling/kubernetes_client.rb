# frozen_string_literal: true

require 'json'
require 'time'
require_relative '../../../lib/gitlab/popen' unless defined?(Gitlab::Popen)

module Tooling
  class KubernetesClient
    RESOURCE_LIST = 'ingress,svc,pdb,hpa,deploy,statefulset,job,pod,secret,configmap,pvc,secret,clusterrole,clusterrolebinding,role,rolebinding,sa,crd'
    CommandFailedError = Class.new(StandardError)

    attr_reader :namespace

    def initialize(namespace:)
      @namespace = namespace
    end

    def cleanup_by_release(release_name:, wait: true)
      delete_by_selector(release_name: release_name, wait: wait)
      delete_by_matching_name(release_name: release_name)
    end

    def cleanup_by_created_at(resource_type:, created_before:, wait: true)
      resource_names = resource_names_created_before(resource_type: resource_type, created_before: created_before)
      return if resource_names.empty?

      delete_by_exact_names(resource_type: resource_type, resource_names: resource_names, wait: wait)
    end

    def cleanup_review_app_namespaces(created_before:, wait: true)
      namespaces = review_app_namespaces_created_before(created_before: created_before)
      return if namespaces.empty?

      delete_namespaces_by_exact_names(resource_names: namespaces, wait: wait)
    end

    private

    def delete_by_selector(release_name:, wait:)
      selector = case release_name
                 when String
                   %(-l release="#{release_name}")
                 when Array
                   %(-l 'release in (#{release_name.join(', ')})')
                 else
                   raise ArgumentError, 'release_name must be a string or an array'
                 end

      command = [
        'delete',
        RESOURCE_LIST,
        %(--namespace "#{namespace}"),
        '--now',
        '--ignore-not-found',
        %(--wait=#{wait}),
        selector
      ]

      run_command(command)
    end

    def delete_by_exact_names(resource_names:, wait:, resource_type: nil)
      command = [
        'delete',
        resource_type,
        %(--namespace "#{namespace}"),
        '--now',
        '--ignore-not-found',
        %(--wait=#{wait}),
        resource_names.join(' ')
      ]

      run_command(command)
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

    def delete_by_matching_name(release_name:)
      resource_names = raw_resource_names
      command = [
        'delete',
        %(--namespace "#{namespace}"),
        '--ignore-not-found'
      ]

      Array(release_name).each do |release|
        resource_names
          .select { |resource_name| resource_name.include?(release) }
          .each { |matching_resource| run_command(command + [matching_resource]) }
      end
    end

    def raw_resource_names
      command = [
        'get',
        RESOURCE_LIST,
        %(--namespace "#{namespace}"),
        '-o name'
      ]
      run_command(command).lines.map(&:strip)
    end

    def resource_names_created_before(resource_type:, created_before:)
      command = [
        'get',
        resource_type,
        %(--namespace "#{namespace}"),
        "--sort-by='{.metadata.creationTimestamp}'",
        '-o json'
      ]

      response = run_command(command)

      resources_created_before_date(response, created_before)
    end

    def review_app_namespaces_created_before(created_before:)
      command = [
        'get',
        'namespace',
        "-l tls=review-apps-tls", # Get only namespaces used for review-apps
        "--sort-by='{.metadata.creationTimestamp}'",
        '-o json'
      ]

      response = run_command(command)

      resources_created_before_date(response, created_before)
    end

    def resources_created_before_date(response, date)
      items = JSON.parse(response)['items'] # rubocop:disable Gitlab/Json

      items.filter_map do |item|
        item_created_at = Time.parse(item.dig('metadata', 'creationTimestamp'))

        item.dig('metadata', 'name') if item_created_at < date
      end
    rescue ::JSON::ParserError => ex
      puts "Ignoring this JSON parsing error: #{ex}\n\nResponse was:\n#{response}" # rubocop:disable Rails/Output
      []
    end

    def run_command(command)
      final_command = ['kubectl', *command.compact].join(' ')
      puts "Running command: `#{final_command}`" # rubocop:disable Rails/Output

      result = Gitlab::Popen.popen_with_detail([final_command])

      if result.status.success?
        result.stdout.chomp.freeze
      else
        raise CommandFailedError, "The `#{final_command}` command failed (status: #{result.status}) with the following error:\n#{result.stderr}"
      end
    end
  end
end
