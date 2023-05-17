# frozen_string_literal: true

module Ci
  module TemplateHelpers
    def template_registry_host
      'registry.gitlab.com'
    end

    def auto_build_image_repository
      "gitlab-org/cluster-integration/auto-build-image"
    end

    def public_image_exist?(registry, repository, image)
      public_image_manifest(registry, repository, image).present?
    end

    def public_image_manifest(registry, repository, reference)
      token = public_image_repository_token(registry, repository)

      headers = {
        'Authorization' => "Bearer #{token}",
        'Accept' => 'application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.oci.image.index.v1+json'
      }
      response = with_net_connect_allowed do
        Gitlab::HTTP.get(image_manifest_url(registry, repository, reference), headers: headers)
      end

      if response.success?
        Gitlab::Json.parse(response.body)
      elsif response.not_found?
        nil
      else
        raise "Could not retrieve manifest: #{response.body}"
      end
    end

    def public_image_repository_token(registry, repository)
      @public_image_repository_tokens ||= {}
      @public_image_repository_tokens[[registry, repository]] ||=
        begin
          response = with_net_connect_allowed do
            Gitlab::HTTP.get(image_manifest_url(registry, repository, 'latest'))
          end

          raise 'Unauthorized' unless response.unauthorized?

          www_authenticate = response.headers['www-authenticate']
          raise 'Missing www-authenticate' unless www_authenticate

          realm, service, scope = www_authenticate.split(',').map { |s| s[/\w+="(.*)"/, 1] }
          token_response = with_net_connect_allowed do
            Gitlab::HTTP.get(realm, query: { service: service, scope: scope })
          end

          raise "Could not get token: #{token_response.body}" unless token_response.success?

          token_response['token']
        end
    end

    def image_manifest_url(registry, repository, reference)
      "#{registry}/v2/#{repository}/manifests/#{reference}"
    end
  end
end

Ci::TemplateHelpers.prepend_mod
