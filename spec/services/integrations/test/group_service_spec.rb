# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Test::GroupService, feature_category: :integrations do
  include AfterNextHelpers

  describe '#execute' do
    let_it_be(:group) { create(:group) }
    let_it_be(:integration) { create(:integrations_slack, :group, group: group) }
    let_it_be(:user) { create(:user) }

    let(:event) { nil }
    let(:sample_data) { { data: 'sample' } }
    let(:success_result) { { success: true, result: {} } }

    subject(:test_service) { described_class.new(integration, user, event).execute }

    before_all do
      group.add_owner(user)
    end

    context 'without event specified' do
      it 'tests the integration with default data' do
        allow(Gitlab::DataBuilder::Push).to receive(:sample_data).and_return(sample_data)

        expect(integration).to receive(:test).with(sample_data).and_return(success_result)
        expect(test_service).to eq(success_result)
      end
    end

    context 'with event specified' do
      context 'if event is not supported by integration' do
        let_it_be(:integration) { create(:jira_integration, :group, group: group) }
        let(:event) { 'push' }

        it 'returns error message' do
          expect(test_service).to include({ status: :error, message: 'Testing not available for this event' })
        end
      end

      context 'for `push` event' do
        let(:event) { 'push' }

        it 'executes integration' do
          allow(Gitlab::DataBuilder::Push).to receive(:sample_data).and_return(sample_data)

          expect(integration).to receive(:test).with(sample_data).and_return(success_result)
          expect(test_service).to eq(success_result)
        end
      end

      context 'for `tag_push` event' do
        let(:event) { 'tag_push' }

        it 'executes integration' do
          allow(Gitlab::DataBuilder::Push).to receive(:sample_data).and_return(sample_data)

          expect(integration).to receive(:test).with(sample_data).and_return(success_result)
          expect(test_service).to eq(success_result)
        end
      end
    end
  end
end
