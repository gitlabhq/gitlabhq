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

      it 'redirects with a notice when accepted' do
        accept_invite

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to match(/You have approved the reassignment/)
      end

      it 'can only be accepted by the reassign_to_user' do
        source_user.update!(reassign_to_user: create(:user))

        expect { accept_invite }.not_to change { source_user.reload.status }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'cannot be accepted twice' do
        source_user.accept!

        accept_invite

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/could not be accepted/)
      end
    end

    it_behaves_like 'it requires feature flag'
    it_behaves_like 'it requires the user to be signed in'
  end

  describe 'POST /decline' do
    let(:path) { decline_import_source_user_path(source_user) }

    subject(:reject_invite) { post path }

    context 'when signed in' do
      before do
        sign_in(source_user.reassign_to_user)
      end

      it { expect { reject_invite }.to change { source_user.reload.rejected? }.from(false).to(true) }
      it { expect { reject_invite }.to change { source_user.reload.reassign_to_user }.from(instance_of(User)).to(nil) }

      it 'redirects with a notice' do
        reject_invite

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to match(/You have rejected the reassignment/)
      end

      it 'cannot be declined after being accepted' do
        source_user.accept!

        reject_invite

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/could not be declined/)
      end
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

      it 'shows the reassignment invite only to reassign_to_user' do
        source_user.update!(reassign_to_user: create(:user))

        show_invite

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'is only valid to source users awaiting approval' do
        source_user.accept!

        show_invite

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/The invitation is not valid/)
      end
    end

    it_behaves_like 'it requires feature flag'
    it_behaves_like 'it requires the user to be signed in'
  end
end
