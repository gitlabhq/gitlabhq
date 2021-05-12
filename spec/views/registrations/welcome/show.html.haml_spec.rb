# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'registrations/welcome/show' do
  let(:is_gitlab_com) { false }

  let_it_be(:user) { create(:user) }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:in_subscription_flow?).and_return(false)
    allow(view).to receive(:in_trial_flow?).and_return(false)
    allow(view).to receive(:user_has_memberships?).and_return(false)
    allow(view).to receive(:in_oauth_flow?).and_return(false)
    allow(Gitlab).to receive(:com?).and_return(is_gitlab_com)

    render
  end

  subject { rendered }

  it { is_expected.not_to have_selector('label[for="user_setup_for_company"]') }
  it { is_expected.to have_button('Get started!') }
  it { is_expected.to have_selector('input[name="user[email_opted_in]"]') }

  describe 'email opt in' do
    context 'when on gitlab.com' do
      let(:is_gitlab_com) { true }

      it 'hides the email-opt in by default' do
        expect(subject).to have_css('.js-email-opt-in.hidden')
      end
    end

    context 'when not on gitlab.com' do
      let(:is_gitlab_com) { false }

      it 'hides the email-opt in by default' do
        expect(subject).not_to have_css('.js-email-opt-in.hidden')
        expect(subject).to have_css('.js-email-opt-in')
      end
    end
  end
end
