# frozen_string_literal: true

RSpec.shared_examples 'request_accessable' do
  context 'when not signed in' do
    it 'redirects to sign in page' do
      request

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context 'when signed in' do
    before do
      sign_in(user)
    end

    it 'redirects back to group members page and displays the relevant notice' do
      request

      expect(response).to redirect_to(membershipable_path)
      expect(flash[:notice]).to eq(_('Your request for access has been queued for review.'))
    end

    context 'when something goes wrong' do
      before do
        group_member = build(:group_member)
        request_access_service = instance_double(Members::RequestAccessService)
        allow(Members::RequestAccessService).to receive(:new).and_return(request_access_service)
        allow(request_access_service).to receive(:execute).and_return(group_member)
        allow(group_member).to receive_message_chain(:errors, :full_messages, :to_sentence).and_return('Error')
      end

      it 'redirects back to group members page and displays the relevant notice' do
        request

        expect(response).to redirect_to(membershipable_path)
        expect(flash[:alert]).to eq(_('Your request for access could not be processed: Error'))
      end
    end

    context 'when already a direct member' do
      before do
        membershipable.add_developer(user)
      end

      it 'redirects back to group members page and displays the relevant notice' do
        request

        expect(response).to redirect_to(membershipable_path)
        expect(flash[:notice]).to eq(_('You already have access.'))
      end
    end

    context 'when already an indirect member' do
      before do
        membershipable.parent.add_developer(user)
      end

      it 'redirects back to group members page and displays the relevant notice' do
        request

        expect(response).to redirect_to(membershipable_path)
        expect(flash[:notice]).to eq(_('You already have access.'))
      end
    end

    context 'when a pending access request exists' do
      before do
        membershipable.request_access(user)
      end

      it 'redirects back to group members page and displays the relevant notice' do
        request

        expect(response).to redirect_to(membershipable_path)
        expect(flash[:notice]).to eq(_('You have already requested access.'))
      end
    end
  end
end
