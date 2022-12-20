# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveInvalidIntegrations, :migration, feature_category: :integrations do
  describe '#up' do
    let!(:integrations) { table(:integrations) }

    let!(:valid_integration) { integrations.create!(type_new: 'Foo') }
    let!(:invalid_integration) { integrations.create! }

    it 'removes invalid integrations', :aggregate_failures do
      expect { migrate! }
        .to change { integrations.pluck(:id) }.to(contain_exactly(valid_integration.id))
    end

    context 'when there are many invalid integrations' do
      before do
        stub_const('RemoveInvalidIntegrations::BATCH_SIZE', 3)
        5.times { integrations.create! }
      end

      it 'removes them all' do
        migrate!

        expect(integrations.pluck(:type_new)).to all(be_present)
      end
    end
  end
end
