# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/group', :with_current_organization, feature_category: :groups_and_projects do
  let_it_be(:group) { create(:group) } # rubocop:todo RSpec/FactoryBot/AvoidCreate
  let(:invite_member) { true }
  let(:user) { build_stubbed(:user) }

  before do
    assign(:group, group)
    allow(view).to receive_messages(
      can_invite_group_member?: invite_member,
      current_user_mode: Gitlab::Auth::CurrentUserMode.new(user),
      current_user: user
    )
  end

  subject do
    render

    rendered
  end

  context 'with ability to invite members' do
    it { is_expected.to have_selector('.js-invite-members-modal') }
  end

  context 'without ability to invite members' do
    let(:invite_member) { false }

    it { is_expected.not_to have_selector('.js-invite-members-modal') }
  end
end
