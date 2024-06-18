# frozen_string_literal: true

module Integrations
  module TestHelpers
    def factory_for(integration)
      return :integrations_slack if integration.is_a?(Integrations::Slack)

      "#{integration.to_param}_integration".to_sym
    end

    def integration_factory(integration_name)
      integration_klass = Integration.integration_name_to_model(integration_name)
      integration_instance = integration_klass.new
      factory_for(integration_instance)
    end
  end
end
