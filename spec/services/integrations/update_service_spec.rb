# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::UpdateService, feature_category: :integrations do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:integration) { create(:telegram_integration) }

  let(:service) { described_class.new(current_user: user, integration: integration, attributes: attributes) }

  shared_examples 'error request' do |message|
    it 'returns an error response' do
      result

      expect(result).to be_error
      expect(result.message).to include(message)
    end
  end

  shared_examples 'success request' do
    it 'returns a success response' do
      result

      expect(result).to be_success
      expect(result.payload).to eq(integration)
    end
  end

  describe '#execute' do
    subject(:result)  { service.execute }

    context 'when the integration is not present' do
      let(:integration) { nil }
      let(:attributes) { { thread: 123 } }

      it_behaves_like 'error request', 'Integration not found.'
    end

    context 'when `use_inherited_settings` is true' do
      let(:attributes) { { use_inherited_settings: 'true', thread: 123 } }

      context 'without default integration' do
        it_behaves_like 'error request', 'Default integration not found.'
      end

      context 'with default integration' do
        let_it_be(:default_integration) { create(:telegram_integration, :instance) }

        context 'when the update is successful' do
          it 'sets the inherit_from_id to the default_integration id' do
            allow_next_instance_of(Integrations::Propagation::BulkUpdateService) do |instance|
              allow(instance).to receive(:execute).and_return(true)
            end

            expect { result }.to change { integration.reload.inherit_from_id }.from(nil).to(default_integration.id)
          end

          it 'does not update the integration with the given attributes' do
            expect { result }.not_to change { integration.reload.thread }
          end

          it 'calls the BulkUpdateService' do
            bulk_update_service = instance_double(Integrations::Propagation::BulkUpdateService)
            allow(Integrations::Propagation::BulkUpdateService).to receive(:new).and_return(bulk_update_service)
            allow(bulk_update_service).to receive(:execute)

            result

            expect(Integrations::Propagation::BulkUpdateService).to have_received(:new).with(default_integration,
              [integration])
            expect(bulk_update_service).to have_received(:execute)
          end

          it_behaves_like 'success request'
        end

        context 'when the update fails' do
          before do
            allow(integration).to receive(:save).and_return(false)
          end

          it_behaves_like 'error request', 'Failed to update integration.'
        end
      end
    end

    context 'when `use_inherited_settings` is false' do
      let_it_be(:group_integration) { create(:telegram_integration, :group) }
      let_it_be_with_reload(:integration) { create(:telegram_integration, inherit_from_id: group_integration.id) }

      let(:attributes) { { use_inherited_settings: false, thread: 123 } }

      context 'when the integration is present' do
        context 'and the update is successful' do
          it_behaves_like 'success request'

          it 'sets inherit_from_id to nil' do
            expect { result }.to change { integration.reload.inherit_from_id }.from(group_integration.id).to(nil)
          end

          it 'updates the integration with the given attributes' do
            expect { result }.to change { integration.reload.thread }.from(nil).to(123)
          end
        end

        context 'and the update fails' do
          let(:attributes) { { use_inherited_settings: false, thread: "invalid" } }

          it_behaves_like 'error request', 'Failed to update integration.'
        end
      end

      context 'when the integration is not present' do
        let(:integration) { nil }

        it_behaves_like 'error request', 'Integration not found.'
      end
    end

    context 'without `use_inherited_settings` settings' do
      let(:attributes) { { thread: 123 } }

      context 'when the integration is present' do
        context 'and the update is successful' do
          it_behaves_like 'success request'

          it 'updates the integration with the given attributes' do
            expect { result }.to change { integration.reload.thread }.from(nil).to(123)
          end
        end

        context 'and the update fails' do
          let(:attributes) { { thread: "invalid" } }

          it_behaves_like 'error request', 'Failed to update integration.'
        end
      end

      context 'when the integration inherits' do
        let_it_be(:group) { create(:group) }
        let_it_be(:project) { create(:project, group: group) }
        let_it_be(:group_integration) { create(:telegram_integration, :group, group: group) }
        let_it_be_with_reload(:integration) do
          create(:telegram_integration, project: project, inherit_from_id: group_integration.id)
        end

        it_behaves_like 'success request'

        it 'does not unset inherit_from_id' do
          expect { result }.not_to change { integration.reload.inherit_from_id }.from(group_integration.id)
        end

        it 'does not update the integration with the given attributes' do
          expect { result }.not_to change { integration.reload.thread }
        end
      end

      context 'when the integration is not present' do
        let(:integration) { nil }

        it_behaves_like 'error request', 'Integration not found.'
      end
    end
  end
end
