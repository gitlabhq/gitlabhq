# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUsers::KeepAllAsPlaceholderService, :aggregate_failures, feature_category: :importers do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:user) { namespace.owner }
  let_it_be(:current_user) { user }

  let(:service) { described_class.new(namespace, current_user: current_user) }

  describe '#execute' do
    context 'when the current user has access' do
      let!(:source_user_pending_assignment_1) do
        create(:import_source_user, :pending_reassignment, namespace: namespace, source_hostname: 'https://gitea.com')
      end

      let!(:source_user_pending_assignment_2) do
        create(:import_source_user, :pending_reassignment, namespace: namespace)
      end

      let!(:source_user_rejected) { create(:import_source_user, :rejected, namespace: namespace) }
      let!(:source_user_awaiting_approval) { create(:import_source_user, :awaiting_approval, namespace: namespace) }

      before do
        stub_const("#{described_class.name}::BATCH_SIZE", 2)
      end

      it 'reassigns all reassignable placeholders to stay as placeholders in the namespace' do
        reassignable_source_users = [
          source_user_pending_assignment_1, source_user_pending_assignment_2, source_user_rejected
        ]

        service.execute

        reassignable_source_users.each(&:reload)
        expect(reassignable_source_users.all?(&:keep_as_placeholder?)).to be(true)
        expect(reassignable_source_users.all? { |su| su.reassigned_by_user_id == current_user.id }).to be(true)
        expect(reassignable_source_users.all? { |su| su.reassign_to_user_id.nil? }).to be(true)
        expect(source_user_awaiting_approval.reload.keep_as_placeholder?).to be(false)
      end

      it 'returns success and number of placeholders updated' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload).to eq(3)
      end
    end

    context 'when current user does not have permission' do
      let_it_be(:current_user) { create(:user) }

      it 'returns error no permissions' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq('You have insufficient permissions to update the import source user')
      end
    end
  end
end
