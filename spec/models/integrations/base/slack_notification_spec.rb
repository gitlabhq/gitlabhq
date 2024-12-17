# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Base::SlackNotification, feature_category: :integrations do
  # This spec should only contain tests that cannot be tested through
  # `base_slack_notification_shared_examples.rb`.

  let(:integration_class) do
    Class.new(Integration) do
      include Integrations::Base::SlackNotification
    end
  end

  before do
    stub_const('TestIntegration', integration_class)
  end

  subject(:integration) { integration_class.new }

  describe '#metrics_key_prefix (private method)' do
    it 'raises a NotImplementedError error when not defined' do
      expect { integration.send(:metrics_key_prefix) }.to raise_error(NotImplementedError)
    end
  end
end
