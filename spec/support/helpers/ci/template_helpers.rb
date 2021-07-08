# frozen_string_literal: true

module Ci
  module TemplateHelpers
    def secure_analyzers_prefix
      'registry.gitlab.com/gitlab-org/security-products/analyzers'
    end
  end
end

Ci::TemplateHelpers.prepend_mod
