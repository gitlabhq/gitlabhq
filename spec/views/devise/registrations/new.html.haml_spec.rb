# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/registrations/new', feature_category: :system_access do
  let(:resource) { Users::RegistrationsBuildService.new(nil, {}).execute }
  let(:tracking_label) { '_some_registration_' }
  let(:onboarding_status_presenter) { instance_double(::Onboarding::StatusPresenter, registration_omniauth_params: {}) }

  subject { render && rendered }

  before do
    allow(view).to receive(:onboarding_status_presenter).and_return(onboarding_status_presenter)
    allow(view).to receive(:resource).and_return(resource)
    allow(view).to receive(:resource_name).and_return(:user)
    allow(view).to receive(:preregistration_tracking_label).and_return(tracking_label)
    allow(view).to receive(:arkose_labs_enabled?)
  end

  context 'for password form' do
    it { is_expected.to have_css('form[action="/users"]') }
  end

  context 'for omniauth provider buttons' do
    let(:provider_label) { :github }
    let(:tracking_action) { "#{provider_label}_sso" }

    before do
      allow(view).to receive(:providers).and_return([provider_label])
    end

    it { is_expected.to have_tracking(action: tracking_action, label: tracking_label) }
    it { is_expected.to have_content(_('Continue with:')) }
    it { is_expected.to have_css('form[action="/users/auth/github"]') }
  end

  context 'without broadcast messaging' do
    it { is_expected.not_to render_template('layouts/_broadcast') }
  end
end
