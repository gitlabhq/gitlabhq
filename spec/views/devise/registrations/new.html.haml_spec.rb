# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/registrations/new', feature_category: :system_access do
  let(:resource) { Users::RegistrationsBuildService.new(nil, {}).execute }
  let(:tracking_label) { '_some_registration_' }
  let(:onboarding_status_presenter) { ::Onboarding::StatusPresenter.new({}, nil, resource) }

  subject { render && rendered }

  before do
    allow(view).to receive_messages(
      onboarding_status_presenter: onboarding_status_presenter,
      resource: resource,
      resource_name: :user,
      preregistration_tracking_label: tracking_label
    )
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
