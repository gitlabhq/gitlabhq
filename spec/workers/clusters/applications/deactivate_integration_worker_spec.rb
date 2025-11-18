# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Applications::DeactivateIntegrationWorker, '#perform', feature_category: :deployment_management do
  context 'when cluster does not exist' do
    it 'does not raise Record Not Found error' do
      expect { described_class.new.perform(0, 'ignored in this context') }.not_to raise_error
    end
  end
end
