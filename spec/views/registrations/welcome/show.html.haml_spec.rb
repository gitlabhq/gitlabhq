# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'registrations/welcome/show' do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { User.new }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:in_subscription_flow?).and_return(false)
    allow(view).to receive(:in_trial_flow?).and_return(false)
    allow(view).to receive(:in_invitation_flow?).and_return(false)
    allow(view).to receive(:in_oauth_flow?).and_return(false)
    allow(view).to receive(:experiment_enabled?).with(:onboarding_issues).and_return(false)
    allow(Gitlab).to receive(:com?).and_return(false)

    render
  end

  subject { rendered }

  it { is_expected.not_to have_selector('label[for="user_setup_for_company"]') }
  it { is_expected.to have_button('Get started!') }
end
