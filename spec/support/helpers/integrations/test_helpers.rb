# frozen_string_literal: true

module Integrations
  module TestHelpers
    def factory_for(integration)
      return :integrations_slack if integration.is_a?(Integrations::Slack)

      "#{integration.to_param}_integration".to_sym
    end
  end
end
