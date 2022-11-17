# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::BaseSlackNotification do
  # This spec should only contain tests that cannot be tested through
  # `base_slack_notification_shared_examples.rb`.

  describe '#metrics_key_prefix (private method)' do
    it 'raises a NotImplementedError error when not defined' do
      subclass = Class.new(described_class)

      expect { subclass.new.send(:metrics_key_prefix) }.to raise_error(NotImplementedError)
    end
  end
end
