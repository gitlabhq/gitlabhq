# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/project', feature_category: :groups_and_projects do
  let(:invite_member) { true }

  before do
    project_namespace = build_stubbed(:project_namespace)
    project = build_stubbed(:project, project_namespace: project_namespace)
    assign(:project, project)
    user = build_stubbed(:user)

    allow(view).to receive_messages(current_user_mode: Gitlab::Auth::CurrentUserMode.new(user), current_user: user)
    allow(view).to receive(:can?).with(user, :invite_member, project).and_return(invite_member)
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
