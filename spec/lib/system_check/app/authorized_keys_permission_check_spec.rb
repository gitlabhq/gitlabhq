# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemCheck::App::AuthorizedKeysPermissionCheck do
  subject(:system_check) { described_class.new }

  describe '#skip?' do
    subject { system_check.skip? }

    context 'authorized keys enabled' do
      it { is_expected.to eq(false) }
    end

    context 'authorized keys not enabled' do
      before do
        stub_application_setting(authorized_keys_enabled: false)
      end

      it { is_expected.to eq(true) }
    end
  end

  describe '#check?' do
    subject { system_check.check? }

    before do
      expect_next_instance_of(Gitlab::AuthorizedKeys) do |instance|
        allow(instance).to receive(:accessible?) { accessible? }
      end
    end

    context 'authorized keys is accessible' do
      let(:accessible?) { true }

      it { is_expected.to eq(true) }
    end

    context 'authorized keys is not accessible' do
      let(:accessible?) { false }

      it { is_expected.to eq(false) }
    end
  end

  describe '#repair!' do
    subject { system_check.repair! }

    before do
      expect_next_instance_of(Gitlab::AuthorizedKeys) do |instance|
        allow(instance).to receive(:create) { created }
      end
    end

    context 'authorized_keys file created' do
      let(:created) { true }

      it { is_expected.to eq(true) }
    end

    context 'authorized_keys file is not created' do
      let(:created) { false }

      it { is_expected.to eq(false) }
    end
  end
end
