# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ExternalAuthorization, :request_store do
  include ExternalAuthorizationServiceHelpers

  let(:user) { build(:user) }
  let(:label) { 'dummy_label' }

  describe '#access_allowed?' do
    it 'is always true when the feature is disabled' do
      # Not using `stub_application_setting` because the method is prepended in
      # `EE::ApplicationSetting` which breaks when using `any_instance`
      # https://gitlab.com/gitlab-org/gitlab-foss/issues/33587
      expect(::Gitlab::CurrentSettings.current_application_settings)
        .to receive(:external_authorization_service_enabled) { false }

      expect(described_class).not_to receive(:access_for_user_to_label)

      expect(described_class.access_allowed?(user, label)).to be_truthy
    end
  end

  describe '#rejection_reason' do
    it 'is always nil when the feature is disabled' do
      expect(::Gitlab::CurrentSettings.current_application_settings)
        .to receive(:external_authorization_service_enabled) { false }

      expect(described_class).not_to receive(:access_for_user_to_label)

      expect(described_class.rejection_reason(user, label)).to be_nil
    end
  end

  describe '#access_for_user_to_label' do
    it 'only loads the access once per request' do
      enable_external_authorization_service_check

      expect(::Gitlab::ExternalAuthorization::Access)
        .to receive(:new).with(user, label).once.and_call_original

      2.times { described_class.access_for_user_to_label(user, label, nil) }
    end

    it 'logs the access request once per request' do
      expect(::Gitlab::ExternalAuthorization::Logger)
        .to receive(:log_access)
              .with(an_instance_of(::Gitlab::ExternalAuthorization::Access),
                'the/project/path')
              .once

      2.times { described_class.access_for_user_to_label(user, label, 'the/project/path') }
    end
  end
end
