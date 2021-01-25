# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Credentials::Registry::DependencyProxy do
  let(:build) { create(:ci_build, name: 'spinach', stage: 'test', stage_idx: 0) }
  let(:gitlab_url) { 'gitlab.example.com:443' }

  subject { described_class.new(build) }

  before do
    stub_config_setting(host: 'gitlab.example.com', port: 443)
  end

  it 'contains valid dependency proxy credentials' do
    expect(subject).to be_kind_of(described_class)

    expect(subject.username).to eq 'gitlab-ci-token'
    expect(subject.password).to eq build.token
    expect(subject.url).to eq gitlab_url
    expect(subject.type).to eq 'registry'
  end

  describe '.valid?' do
    subject { described_class.new(build).valid? }

    context 'when dependency proxy is enabled' do
      before do
        stub_config(dependency_proxy: { enabled: true })
      end

      it { is_expected.to be_truthy }
    end

    context 'when dependency proxy is disabled' do
      before do
        stub_config(dependency_proxy: { enabled: false })
      end

      it { is_expected.to be_falsey }
    end
  end
end
