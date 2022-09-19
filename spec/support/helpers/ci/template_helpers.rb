# frozen_string_literal: true

module Ci
  module TemplateHelpers
    def template_registry_host
      'registry.gitlab.com'
    end
  end
end

Ci::TemplateHelpers.prepend_mod
