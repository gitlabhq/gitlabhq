# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::IntegrationsCheck, feature_category: :source_code_management do
  describe '#validate!' do
    include_context 'changes access checks context'
    subject(:integration_check) { described_class.new(changes_access) }

    it 'calls integration push checks validate method' do
      expect_next_instance_of(::Gitlab::Checks::Integrations::BeyondIdentityCheck) do |instance|
        expect(instance).to receive(:validate!)
      end

      integration_check.validate!
    end
  end
end
