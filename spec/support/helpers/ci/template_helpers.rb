# frozen_string_literal: true

module Ci
  module TemplateHelpers
    def secure_analyzers_prefix
      'registry.gitlab.com/security-products'
    end

    def template_registry_host
      'registry.gitlab.com'
    end
  end
end

Ci::TemplateHelpers.prepend_mod
