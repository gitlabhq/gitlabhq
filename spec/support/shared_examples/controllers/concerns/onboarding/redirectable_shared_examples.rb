# frozen_string_literal: true

RSpec.shared_examples Onboarding::Redirectable do
  it { is_expected.to redirect_to dashboard_projects_path }

  context 'when the new user already has any accepted group membership' do
    let!(:single_member) { create(:group_member, invite_email: email) }

    it 'redirects to the group path with a flash message' do
      post_create

      expect(response).to redirect_to group_path(single_member.source)
      expect(controller).to set_flash[:notice].to(/You have been granted/)
    end

    context 'when the new user already has more than 1 accepted group membership' do
      let!(:last_member) { create(:group_member, invite_email: email) }

      it 'redirects to the last member group path without a flash message' do
        post_create

        expect(response).to redirect_to group_path(last_member.source)
        expect(controller).not_to set_flash[:notice].to(/You have been granted/)
      end
    end

    context 'when the member has an orphaned source at the time of registering' do
      before do
        single_member.source.delete
      end

      it { is_expected.to redirect_to dashboard_projects_path }
    end
  end
end
