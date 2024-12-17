# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUsers::ReassignService, feature_category: :importers do
  let(:import_source_user) { create(:import_source_user) }
  let(:user) { import_source_user.namespace.owner }
  let(:current_user) { user }
  let(:assignee_user) { create(:user) }
  let(:service) { described_class.new(import_source_user, assignee_user, current_user: current_user) }

  describe '#execute' do
    context 'when reassignment is successful' do
      it 'returns success' do
        expect(Notify).to receive_message_chain(:import_source_user_reassign, :deliver_now)

        result = service.execute

        expect(result).to be_success
        expect(result.payload.reload).to eq(import_source_user)
        expect(result.payload.reassign_to_user).to eq(assignee_user)
        expect(result.payload.reassigned_by_user).to eq(current_user)
        expect(result.payload.awaiting_approval?).to eq(true)
      end
    end

    shared_examples 'an error response' do |desc, error:|
      it "returns #{desc} error" do
        expect(Notify).not_to receive(:import_source_user_reassign)

        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq(error)
      end
    end

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

    context 'when assignee user does not exist' do
      let(:assignee_user) { nil }

      it_behaves_like 'an error response', 'invalid assignee',
        error: s_('UserMapping|You can assign only active users with regular or auditor access. ' \
          'To assign users with administrator access, ask your GitLab administrator to ' \
          'enable the "Allow contribution mapping to administrators" setting.')
    end

    context 'when assignee user is not a human' do
      let(:assignee_user) { create(:user, :bot) }

      it_behaves_like 'an error response', 'invalid assignee',
        error: s_('UserMapping|You can assign only active users with regular or auditor access. ' \
          'To assign users with administrator access, ask your GitLab administrator to ' \
          'enable the "Allow contribution mapping to administrators" setting.')
    end

    context 'when assignee user is not active' do
      let(:assignee_user) { create(:user, :deactivated) }

      it_behaves_like 'an error response', 'invalid assignee',
        error: s_('UserMapping|You can assign only active users with regular or auditor access. ' \
          'To assign users with administrator access, ask your GitLab administrator to ' \
          'enable the "Allow contribution mapping to administrators" setting.')
    end

    context 'when assignee user is an admin' do
      let(:assignee_user) { create(:user, :admin) }

      it_behaves_like 'an error response', 'invalid assignee',
        error: s_('UserMapping|You can assign only active users with regular or auditor access. ' \
          'To assign users with administrator access, ask your GitLab administrator to ' \
          'enable the "Allow contribution mapping to administrators" setting.')
    end

    context 'when allow_contribution_mapping_to_admins setting is enabled' do
      before do
        stub_application_setting(allow_contribution_mapping_to_admins: true)
      end

      context 'and the assignee user is invalid' do
        let(:assignee_user) { create(:user, :deactivated) }

        it_behaves_like 'an error response', 'invalid assignee',
          error: s_('UserMapping|You can assign users with regular, auditor, or administrator access only.')
      end

      context 'and the assignee user is an admin' do
        let(:assignee_user) { create(:user, :admin) }

        it 'assigns the user' do
          expect(Notify).to receive_message_chain(:import_source_user_reassign, :deliver_now)

          expect(service.execute).to be_success
        end
      end
    end

    context 'when an error occurs' do
      before do
        allow(import_source_user).to receive(:reassign).and_return(false)
        allow(import_source_user).to receive(:errors).and_return(instance_double(ActiveModel::Errors,
          full_messages: ['Error']))
      end

      it_behaves_like 'an error response', 'active record', error: ['Error']
    end
  end
end
