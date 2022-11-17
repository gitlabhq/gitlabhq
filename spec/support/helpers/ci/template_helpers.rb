# frozen_string_literal: true

module Ci
  module TemplateHelpers
    def template_registry_host
      'registry.gitlab.com'
    end

    def public_image_exist?(registry, repository, image)
      public_image_manifest(registry, repository, image).present?
    end

    def public_image_manifest(registry, repository, reference)
      token = public_image_repository_token(registry, repository)

      response = with_net_connect_allowed do
        Gitlab::HTTP.get(image_manifest_url(registry, repository, reference),
                         headers: { 'Authorization' => "Bearer #{token}" })
      end

      return unless response.success?

      Gitlab::Json.parse(response.body)
    end

    def public_image_repository_token(registry, repository)
      @public_image_repository_tokens ||= {}
      @public_image_repository_tokens[[registry, repository]] ||=
        begin
          response = with_net_connect_allowed do
            Gitlab::HTTP.get(image_manifest_url(registry, repository, 'latest'))
          end

          return unless response.unauthorized?

          www_authenticate = response.headers['www-authenticate']
          return unless www_authenticate

          realm, service, scope = www_authenticate.split(',').map { |s| s[/\w+="(.*)"/, 1] }
          token_response = with_net_connect_allowed do
            Gitlab::HTTP.get(realm, query: { service: service, scope: scope })
          end

          return unless token_response.success?

          token_response['token']
        end
    end

    def image_manifest_url(registry, repository, reference)
      "#{registry}/v2/#{repository}/manifests/#{reference}"
    end
  end
end

Ci::TemplateHelpers.prepend_mod
