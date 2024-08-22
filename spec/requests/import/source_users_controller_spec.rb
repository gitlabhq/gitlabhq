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

  shared_examples 'it requires awaiting approval status' do
    it 'show error message' do
      source_user.accept!

      subject

      expect(response).to redirect_to(dashboard_groups_path)
      expect(flash[:alert]).to match(/The invitation is no longer valid./)
    end
  end

  let_it_be_with_reload(:source_user) do
    create(:import_source_user, :with_reassign_to_user, :with_reassigned_by_user, :awaiting_approval)
  end

  describe 'POST /accept' do
    let(:path) { accept_import_source_user_path(source_user) }

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

        expect(response).to redirect_to(dashboard_groups_path)
        expect(flash[:raw]).to match(/Reassignment approved/)
      end

      it 'can only be accepted by the reassign_to_user' do
        source_user.update!(reassign_to_user: create(:user))

        expect { accept_invite }.not_to change { source_user.reload.status }

        expect(response).to redirect_to(dashboard_groups_path)
        expect(flash[:raw]).to match(/Reassignment cancelled/)
      end

      it 'cannot be accepted twice' do
        allow(Import::SourceUser).to receive(:find).and_return(source_user)
        allow(source_user).to receive(:accept).and_return(false)

        accept_invite

        expect(response).to redirect_to(dashboard_groups_path)
        expect(flash[:alert]).to match(/The invitation could not be accepted/)
      end

      it_behaves_like 'it requires awaiting approval status'
    end

    it_behaves_like 'it requires feature flag'
    it_behaves_like 'it requires the user to be signed in'
  end

  describe 'POST /decline' do
    let(:path) { decline_import_source_user_path(source_user) }
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

        expect(response).to redirect_to(dashboard_groups_path)
        expect(flash[:raw]).to match(/Reassignment rejected/)
      end

      it 'cannot be declined twice' do
        allow(Import::SourceUser).to receive(:find).and_return(source_user)
        allow(source_user).to receive(:reject).and_return(false)

        reject_invite

        expect(response).to redirect_to(dashboard_groups_path)
        expect(flash[:alert]).to match(/The invitation could not be declined/)
      end

      it_behaves_like 'it requires awaiting approval status'
    end

    it_behaves_like 'it requires feature flag'
    it_behaves_like 'it requires the user to be signed in'
  end

  describe 'GET /show' do
    let(:path) { import_source_user_path(source_user) }

    subject(:show_invite) { get path }

    context 'when signed in' do
      before do
        sign_in(source_user.reassign_to_user)
      end

      it 'returns a 200 response' do
        show_invite

        expect(response).to have_gitlab_http_status(:success)
      end

      context 'when the user is not the reassign_to_user' do
        it 'does not show invite and shows the invalid invite error message' do
          source_user.update!(reassign_to_user: create(:user))
          source_user.accept!

          show_invite

          expect(response).to redirect_to(dashboard_groups_path)
          expect(flash[:raw]).to match(/Reassignment cancelled/)
        end
      end

      it_behaves_like 'it requires awaiting approval status'
    end

    it_behaves_like 'it requires feature flag'
    it_behaves_like 'it requires the user to be signed in'
  end
end
