# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUsers::ReassignService, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let(:import_source_user) { create(:import_source_user) }
  let(:current_user) { user }
  let(:assignee_user) { create(:user) }
  let(:service) { described_class.new(import_source_user, assignee_user, current_user: current_user) }
  let(:result) { service.execute }

  describe '#execute' do
    before do
      import_source_user.namespace.add_owner(user)
    end

    shared_examples 'a success response' do
      it 'returns success', :aggregate_failures do
        expect(Import::ReassignPlaceholderUserRecordsWorker).not_to receive(:perform_async)
        expect(Notify).to receive_message_chain(:import_source_user_reassign, :deliver_later)
        expect { result }
          .to trigger_internal_events('propose_placeholder_user_reassignment')
          .with(
            namespace: import_source_user.namespace,
            user: current_user,
            additional_properties: {
              label: Gitlab::GlobalAnonymousId.user_id(import_source_user.placeholder_user),
              property: Gitlab::GlobalAnonymousId.user_id(assignee_user),
              import_type: import_source_user.import_type,
              reassign_to_user_state: assignee_user.state
            }
          )

        expect(result).to be_success
        expect(result.payload.reload).to eq(import_source_user)
        expect(result.payload.reassign_to_user).to eq(assignee_user)
        expect(result.payload.reassigned_by_user).to eq(current_user)
        expect(result.payload.awaiting_approval?).to eq(true)
      end
    end

    shared_examples 'a success response that bypasses user confirmation' do
      it 'returns success', :aggregate_failures do
        expect(Import::ReassignPlaceholderUserRecordsWorker).to receive(:perform_async).with(import_source_user.id,
          'confirmation_skipped' => true)
        expect { result }
          .to trigger_internal_events('reassign_placeholder_user_without_confirmation')
          .with(
            namespace: import_source_user.namespace,
            user: current_user,
            additional_properties: {
              label: Gitlab::GlobalAnonymousId.user_id(import_source_user.placeholder_user),
              property: Gitlab::GlobalAnonymousId.user_id(assignee_user),
              import_type: import_source_user.import_type,
              reassign_to_user_state: assignee_user.state
            }
          )

        expect(result).to be_success
        expect(result.payload.reload).to eq(import_source_user)
        expect(result.payload.reassign_to_user).to eq(assignee_user)
        expect(result.payload.reassigned_by_user).to eq(current_user)
        expect(result.payload.reassignment_in_progress?).to eq(true)
      end
    end

    shared_examples 'an error response' do |desc, error:|
      it "returns #{desc} error", :aggregate_failures do
        expect(Notify).not_to receive(:import_source_user_reassign)
        expect(Import::ReassignPlaceholderUserRecordsWorker).not_to receive(:perform_async)

        expect { result }.not_to change { import_source_user.status }

        expect(result).to be_error
        expect(result.message).to eq(error)
      end
    end

    shared_examples 'normal reassignment responses for assignee types' do |assignee_error:, skip_admin: false|
      context 'when assignee user is active and not an admin' do
        it_behaves_like 'a success response'
      end

      context 'when assignee user does not exist' do
        let(:assignee_user) { nil }

        it_behaves_like 'an error response', 'invalid assignee', error: assignee_error
      end

      context 'when assignee user is not a human' do
        let(:assignee_user) { create(:user, :bot) }

        it_behaves_like 'an error response', 'invalid assignee', error: assignee_error
      end

      context 'when assignee user is blocked' do
        let(:assignee_user) { create(:user, :blocked) }

        it_behaves_like 'an error response', 'invalid assignee', error: assignee_error
      end

      context 'when assignee user is banned' do
        let(:assignee_user) { create(:user, :banned) }

        it_behaves_like 'an error response', 'invalid assignee', error: assignee_error
      end

      context 'when assignee user is deactivated' do
        let(:assignee_user) { create(:user, :deactivated) }

        it_behaves_like 'an error response', 'invalid assignee', error: assignee_error
      end

      context 'when assignee user is an admin', unless: skip_admin do
        let(:assignee_user) { create(:user, :admin) }

        it_behaves_like 'an error response', 'invalid assignee', error: assignee_error
      end
    end

    shared_examples 'bypassed reassignment responses for assignee types' do |assignee_error:, skip_admin: false|
      context 'when assignee user is active and not an admin' do
        it_behaves_like 'a success response that bypasses user confirmation'
      end

      context 'when assignee user does not exist' do
        let(:assignee_user) { nil }

        it_behaves_like 'an error response', 'invalid assignee', error: assignee_error
      end

      context 'when assignee user is not a human' do
        let(:assignee_user) { create(:user, :bot) }

        it_behaves_like 'an error response', 'invalid assignee', error: assignee_error
      end

      context 'when assignee user is blocked' do
        let(:assignee_user) { create(:user, :blocked) }

        it_behaves_like 'a success response that bypasses user confirmation'
      end

      context 'when assignee user is banned' do
        let(:assignee_user) { create(:user, :banned) }

        it_behaves_like 'a success response that bypasses user confirmation'
      end

      context 'when assignee user is deactivated' do
        let(:assignee_user) { create(:user, :deactivated) }

        it_behaves_like 'a success response that bypasses user confirmation'
      end

      context 'when assignee user is an admin', unless: skip_admin do
        let(:assignee_user) { create(:user, :admin) }

        it_behaves_like 'an error response', 'invalid assignee', error: assignee_error
      end
    end

    it_behaves_like 'normal reassignment responses for assignee types',
      assignee_error: s_('UserMapping|You can assign active users with regular or auditor access only.')

    context 'when current user does not have permission' do
      let(:current_user) { create(:user) }

      it_behaves_like 'an error response', 'no permissions',
        error: 'You have insufficient permissions to update the import source user'
    end

    context 'when import source user does not have an reassignable status' do
      before do
        allow(current_user).to receive(:can?).with(:admin_import_source_user, import_source_user).and_return(true)
        allow(import_source_user).to receive(:reassignable_status?).and_return(false)
      end

      it_behaves_like 'an error response', 'invalid status',
        error: 'Import source user has an invalid status for this operation'
    end

    context 'when allow_contribution_mapping_to_admins setting is enabled' do
      before do
        stub_application_setting(allow_contribution_mapping_to_admins: true)
      end

      it_behaves_like 'normal reassignment responses for assignee types',
        assignee_error: s_(
          'UserMapping|You can assign active users with regular, auditor, or administrator access only.'
        ), skip_admin: true do
        context 'and the assignee user is an admin' do
          let(:assignee_user) { create(:user, :admin) }

          it_behaves_like 'a success response'
        end
      end

      context 'and admin bypass placeholder confirmation is enabled', :enable_admin_mode do
        let_it_be(:current_user) { create(:user, :admin) }

        before do
          stub_application_setting(allow_bypass_placeholder_confirmation: true)
          stub_config_setting(impersonation_enabled: true)
        end

        it_behaves_like 'bypassed reassignment responses for assignee types',
          assignee_error: s_('UserMapping|You can assign users with regular, auditor, or administrator access only.'),
          skip_admin: true do
          context 'and the assignee user is an admin' do
            let(:assignee_user) { create(:user, :admin) }

            it_behaves_like 'a success response that bypasses user confirmation'
          end
        end

        context 'and the current user is not an admin' do
          let_it_be(:current_user) { user }

          it_behaves_like 'normal reassignment responses for assignee types',
            assignee_error: s_(
              'UserMapping|You can assign active users with regular, auditor, or administrator access only.'
            ), skip_admin: true do
            context 'and the assignee user is an admin' do
              let(:assignee_user) { create(:user, :admin) }

              it_behaves_like 'a success response'
            end
          end
        end

        context 'and user impersonation is not enabled' do
          before do
            stub_config_setting(impersonation_enabled: false)
          end

          it_behaves_like 'normal reassignment responses for assignee types',
            assignee_error: s_(
              'UserMapping|You can assign active users with regular, auditor, or administrator access only.'
            ), skip_admin: true do
            context 'and the assignee user is an admin' do
              let(:assignee_user) { create(:user, :admin) }

              it_behaves_like 'a success response'
            end
          end
        end
      end
    end

    context 'when admin bypass placeholder confirmation is enabled', :enable_admin_mode do
      let_it_be(:current_user) { create(:user, :admin) }

      before do
        stub_application_setting(allow_bypass_placeholder_confirmation: true)
        stub_config_setting(impersonation_enabled: true)
      end

      it_behaves_like 'bypassed reassignment responses for assignee types',
        assignee_error: s_('UserMapping|You can assign users with regular or auditor access only.')

      context 'and the current user is not an admin' do
        let_it_be(:current_user) { user }

        it_behaves_like 'normal reassignment responses for assignee types',
          assignee_error: s_('UserMapping|You can assign active users with regular or auditor access only.')
      end

      context 'and user impersonation is not enabled' do
        before do
          stub_config_setting(impersonation_enabled: false)
        end

        it_behaves_like 'normal reassignment responses for assignee types',
          assignee_error: s_('UserMapping|You can assign active users with regular or auditor access only.')
      end
    end

    context 'when the top level namespace is a personal namespace' do
      let(:personal_import_source_user) { create(:import_source_user, :user_type_namespace) }
      let(:current_user) { personal_import_source_user.namespace.owner }
      let(:service) { described_class.new(personal_import_source_user, assignee_user, current_user: current_user) }

      it_behaves_like 'an error response', 'invalid namespace',
        error: s_("UserMapping|You cannot reassign user contributions of imports to a personal namespace.")
    end

    context 'when an error occurs' do
      before do
        allow(import_source_user).to receive(:reassign).and_return(false)
        allow(import_source_user).to receive(:errors).and_return(instance_double(ActiveModel::Errors,
          full_messages: ['Error']))
      end

      it_behaves_like 'an error response', 'active record', error: ['Error']

      it 'tracks a reassignment event' do
        expect { result }
          .to trigger_internal_events('fail_placeholder_user_reassignment')
          .with(
            namespace: import_source_user.namespace,
            user: current_user,
            additional_properties: {
              label: Gitlab::GlobalAnonymousId.user_id(import_source_user.placeholder_user),
              property: Gitlab::GlobalAnonymousId.user_id(assignee_user),
              import_type: import_source_user.import_type,
              reassign_to_user_state: assignee_user.state
            }
          )
      end
    end
  end
end
