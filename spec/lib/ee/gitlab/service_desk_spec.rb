require 'spec_helper'

describe EE::Gitlab::ServiceDesk, lib: true do
  before do
    allow_any_instance_of(License).to receive(:add_on?).and_call_original
    allow_any_instance_of(License).to receive(:add_on?).with('GitLab_ServiceDesk') { true }
    allow(::Gitlab::IncomingEmail).to receive(:enabled?) { true }
    allow(::Gitlab::IncomingEmail).to receive(:supports_wildcard?) { true }
  end

  subject { described_class.enabled? }

  it { is_expected.to be_truthy }

  context 'when license does not support service desk' do
    before do
      allow_any_instance_of(License).to receive(:add_on?).with('GitLab_ServiceDesk') { false }
    end

    it { is_expected.to be_falsy }
  end

  context 'when incoming emails are disabled' do
    before do
      allow(::Gitlab::IncomingEmail).to receive(:enabled?) { false }
    end

    it { is_expected.to be_falsy }
  end

  context 'when email key is not supported' do
    before do
      allow(::Gitlab::IncomingEmail).to receive(:supports_wildcard?) { false }
    end

    it { is_expected.to be_falsy }
  end
end
