# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/sessions/successful_verification', feature_category: :onboarding do
  let_it_be(:user) { create_default(:user, onboarding_in_progress: true) }

  context 'without a user', :experiment do
    it 'skips experiment' do
      render

      experiment(:lightweight_trial_registration_redesign, actor: user) do |e|
        expect(e).not_to be_enabled
      end
    end
  end

  context 'with a user not during trial registration', :experiment do
    before do
      allow(view).to receive(:current_user).and_return(user)
    end

    it 'skips experiment' do
      render

      experiment(:lightweight_trial_registration_redesign, actor: user) do |e|
        expect(e).not_to be_enabled
      end
    end
  end
end
