# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/project', feature_category: :groups_and_projects do
  let(:invite_member) { true }
  let(:project) { build_stubbed(:project) }

  before do
    allow(view).to receive(:can_admin_project_member?).and_return(invite_member)
    assign(:project, project)
    allow(view).to receive(:current_user_mode).and_return(Gitlab::Auth::CurrentUserMode.new(build_stubbed(:user)))
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

  context 'with no transfer in progress' do
    before do
      allow(project).to receive(:git_transfer_in_progress?).and_return(false)
    end

    it 'does not render the alert' do
      is_expected.not_to have_css('[data-testid="transferring-alert"]')
    end
  end

  context 'with transfer in progress' do
    before do
      allow(project).to receive(:git_transfer_in_progress?).and_return(true)
    end

    it 'renders the alert' do
      is_expected.to have_css('[data-testid="transferring-alert"]')
    end
  end
end
