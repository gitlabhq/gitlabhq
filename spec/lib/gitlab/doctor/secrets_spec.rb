# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Doctor::Secrets do
  let!(:user) { create(:user, otp_secret: "test") }
  let!(:group) { create(:group, :allow_runner_registration_token, runners_token: "test") }
  let!(:project) { create(:project) }
  let!(:grafana_integration) { create(:grafana_integration, project: project, token: "test") }
  let!(:integration) { create(:integration, project: project, properties: { test_key: "test_value" }) }
  let(:logger) { double(:logger).as_null_object }

  subject { described_class.new(logger).run! }

  before do
    allow(Gitlab::Runtime).to receive(:rake?).and_return(true)
  end

  context 'when not ran in a Rake runtime' do
    before do
      allow(Gitlab::Runtime).to receive(:rake?).and_return(false)
    end

    it 'raises an error' do
      expect { subject }.to raise_error(StandardError, 'can only be used in a Rake environment')
    end
  end

  context 'when encrypted attributes are properly set' do
    it 'detects decryptable secrets' do
      expect(logger).to receive(:info).with(/User failures: 0/)
      expect(logger).to receive(:info).with(/Group failures: 0/)

      subject
    end
  end

  context 'when attr_encrypted values are not decrypting' do
    it 'marks undecryptable values as bad' do
      user.encrypted_otp_secret = "invalid"
      user.save!

      expect(logger).to receive(:info).with(/User failures: 1/)

      subject
    end
  end

  context 'when TokenAuthenticatable values are not decrypting' do
    before do
      group.runners_token_encrypted = "invalid"
      group.save!
    end

    it 'marks undecryptable values as bad' do
      expect(logger).to receive(:info).with(/Group failures: 1/)

      subject
    end

    context 'when allow_runner_registration_token is false' do
      before do
        stub_application_setting(allow_runner_registration_token: false)
      end

      it 'does not report error as registration tokens are nil' do
        expect(logger).to receive(:info).with(/Group failures: 0/)

        subject
      end
    end
  end

  context 'when initializers attempt to use encrypted data' do
    it 'skips the initializers and detects bad data' do
      integration.encrypted_properties = "invalid"
      integration.save!

      expect(logger).to receive(:info).with(/Integration failures: 1/)

      subject
    end

    it 'resets the initializers after the task runs' do
      subject

      expect(integration).to receive(:initialize_properties)

      integration.run_callbacks(:initialize)
    end
  end

  context 'when GrafanaIntegration token is set via private method' do
    it 'can access GrafanaIntegration token value' do
      expect(logger).to receive(:info).with(/GrafanaIntegration failures: 0/)

      subject
    end
  end
end
