# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUsersController, feature_category: :importers do
  shared_examples 'it requires feature flag' do
    context 'when :improved_user_mapping is disabled' do
      it 'returns 404' do
        stub_feature_flags(importer_user_mapping: false)

        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_examples 'it requires the user to be signed in' do
    context 'when the user is not signed in' do
      it 'redirects to the login screen' do
        subject

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  shared_examples 'it notifies about unavailable reassignments' do
    it 'shows error message' do
      source_user.accept!

      expect { subject }.not_to change { source_user.reload.status }

      expect(response).to redirect_to(root_path)
      expect(flash[:raw]).to match(/Reassignment not available/)
    end
  end

  shared_examples 'it requires the user is the reassign to user' do
    it 'shows error message' do
      source_user.update!(reassign_to_user: create(:user))

      expect { subject }.not_to change { source_user.reload.status }

      expect(response).to redirect_to(root_path)
      expect(flash[:raw]).to match(/Reassignment not available/)
    end
  end

  let_it_be_with_reload(:source_user) do
    create(:import_source_user, :with_reassigned_by_user, :awaiting_approval)
  end

  let!(:reassignment_token) { source_user.reassignment_token }

  describe 'POST /accept' do
    let(:path) { accept_import_source_user_path(reassignment_token: reassignment_token) }

    subject(:accept_invite) { post path }

    context 'when signed in' do
      before do
        sign_in(source_user.reassign_to_user)
      end

      it { expect { accept_invite }.to change { source_user.reload.reassignment_in_progress? }.from(false).to(true) }

      it 'enqueues the job to reassign contributions' do
        expect(Import::ReassignPlaceholderUserRecordsWorker).to receive(:perform_async).with(source_user.id)

        accept_invite
      end

      it 'redirects with a notice when accepted' do
        accept_invite

        expect(response).to redirect_to(root_path)
        expect(flash[:raw]).to match(/Reassignment approved/)
      end

      it 'cannot be accepted twice' do
        allow(Import::SourceUser).to receive(:find_by_reassignment_token).and_return(source_user)
        allow(source_user).to receive(:accept).and_return(false)

        accept_invite

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/The invitation could not be accepted/)
      end

      it_behaves_like 'it notifies about unavailable reassignments'
      it_behaves_like 'it requires the user is the reassign to user'
    end

    it_behaves_like 'it requires feature flag'
    it_behaves_like 'it requires the user to be signed in'
  end

  describe 'POST /decline' do
    let(:path) { decline_import_source_user_path(reassignment_token: reassignment_token) }

    let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }

    subject(:reject_invite) { post path }

    context 'when signed in' do
      before do
        sign_in(source_user.reassign_to_user)
        allow(message_delivery).to receive(:deliver_now)
        allow(Notify).to receive(:import_source_user_rejected).and_return(message_delivery)
      end

      it { expect { reject_invite }.to change { source_user.reload.rejected? }.from(false).to(true) }

      it 'redirects with a notice' do
        reject_invite

        expect(response).to redirect_to(root_path)
        expect(flash[:raw]).to match(/Reassignment rejected/)
      end

      it 'cannot be declined twice' do
        allow(Import::SourceUser).to receive(:find_by_reassignment_token).and_return(source_user)
        allow(source_user).to receive(:reject).and_return(false)

        reject_invite

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/The invitation could not be declined/)
      end

      it_behaves_like 'it notifies about unavailable reassignments'
      it_behaves_like 'it requires the user is the reassign to user'
    end

    it_behaves_like 'it requires feature flag'
    it_behaves_like 'it requires the user to be signed in'
  end

  describe 'GET /show' do
    let(:path) { import_source_user_path(reassignment_token: reassignment_token) }
    let(:reassignment_token) { source_user.reassignment_token }

    subject(:show_invite) { get path }

    context 'when signed in' do
      before do
        sign_in(source_user.reassign_to_user)
      end

      it 'returns a 200 response' do
        show_invite

        expect(response).to have_gitlab_http_status(:success)
      end

      it_behaves_like 'it notifies about unavailable reassignments'
      it_behaves_like 'it requires the user is the reassign to user'
    end

    it_behaves_like 'it requires feature flag'
    it_behaves_like 'it requires the user to be signed in'
  end
end
