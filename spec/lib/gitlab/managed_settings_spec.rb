# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ManagedSettings, feature_category: :settings do
  def fixture(name)
    Rails.root.join('spec/fixtures/managed_settings', name)
  end

  let(:fixture_file) { fixture('valid.yml') }

  before do
    described_class.reset!
    stub_const("#{described_class}::PATH", fixture_file)
  end

  after do
    described_class.reset!
  end

  describe '.enabled?' do
    subject { described_class.enabled? }

    it { is_expected.to be(true) }

    context 'when the config file is absent' do
      let(:fixture_file) { fixture('does_not_exist.yml') }

      it { is_expected.to be(false) }
    end

    it 'memoizes the file presence until reset!' do
      expect(described_class.enabled?).to be(true)

      stub_const("#{described_class}::PATH", fixture('does_not_exist.yml'))
      expect(described_class.enabled?).to be(true)

      described_class.reset!
      expect(described_class.enabled?).to be(false)
    end
  end

  describe '.managed_by' do
    subject { described_class.managed_by }

    it 'returns the configured name' do
      is_expected.to eq('GitLab Helm Chart')
    end

    context 'when the installation root key is absent' do
      let(:fixture_file) { fixture('settings_only.yml') }

      it { is_expected.to be_nil }
    end

    context 'when neither root key is present' do
      let(:fixture_file) { fixture('without_root_keys.yml') }

      it { is_expected.to be_nil }
    end

    context 'when the file is absent' do
      let(:fixture_file) { fixture('does_not_exist.yml') }

      it { is_expected.to be_nil }
    end
  end

  describe '.all' do
    it 'returns recognized settings with symbolized keys' do
      expect(described_class.all).to eq(sidekiq_timezone_override: 'Europe/London')
    end

    context 'when the file is absent' do
      let(:fixture_file) { fixture('does_not_exist.yml') }

      it 'returns an empty hash' do
        expect(described_class.all).to eq({})
      end
    end

    context 'when the file is empty' do
      let(:fixture_file) { fixture('empty.yml') }

      it 'returns an empty hash' do
        expect(described_class.all).to eq({})
      end
    end

    context 'when the file has no managed_settings root key' do
      let(:fixture_file) { fixture('without_root_keys.yml') }

      it 'returns an empty hash' do
        expect(described_class.all).to eq({})
      end
    end

    context 'when a key is not a real application setting column' do
      let(:fixture_file) { fixture('with_unknown_key.yml') }

      it 'drops the unknown key and logs a warning' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          message: 'Ignoring unknown or unsupported managed setting', setting: 'not_a_real_column'
        )

        expect(described_class.all).to eq(sidekiq_timezone_override: 'Europe/London')
      end
    end

    context 'when the file is malformed' do
      let(:fixture_file) { fixture('malformed.txt') }

      it 'raises instead of silently disabling enforcement' do
        expect { described_class.all }
          .to raise_error(described_class::InvalidConfigurationError, /Failed to parse/)
      end
    end

    context 'when a key is a real column but not in the supported allowlist' do
      let(:fixture_file) { fixture('with_unsupported_key.yml') }

      it 'drops the unsupported key and logs a warning' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          message: 'Ignoring unknown or unsupported managed setting', setting: 'asset_proxy_secret_key'
        )

        expect(described_class.all).to eq(sidekiq_timezone_override: 'Europe/London')
      end
    end
  end

  describe '.keys' do
    it 'returns the recognized column names' do
      expect(described_class.keys).to eq([:sidekiq_timezone_override])
    end
  end

  describe '.managed?' do
    it 'is true for a managed column and accepts strings' do
      expect(described_class.managed?(:sidekiq_timezone_override)).to be(true)
      expect(described_class.managed?('sidekiq_timezone_override')).to be(true)
    end

    it 'is false for an unmanaged column' do
      expect(described_class.managed?(:signup_enabled)).to be(false)
    end
  end

  describe '.[]' do
    it 'returns the enforced value' do
      expect(described_class[:sidekiq_timezone_override]).to eq('Europe/London')
    end
  end

  describe '.validate!' do
    context 'when there are no managed settings' do
      let(:fixture_file) { fixture('does_not_exist.yml') }

      it 'does not raise' do
        expect { described_class.validate! }.not_to raise_error
      end
    end

    context 'when all recognized values are valid' do
      it 'does not raise' do
        expect { described_class.validate! }.not_to raise_error
      end
    end

    context 'when a recognized column has an invalid value' do
      let(:fixture_file) { fixture('invalid_value.yml') }

      it 'raises with the offending column' do
        expect { described_class.validate! }
          .to raise_error(described_class::InvalidConfigurationError, /sidekiq_timezone_override/)
      end
    end
  end

  describe '.apply!' do
    let!(:settings) { create(:application_setting, sidekiq_timezone_override: 'UTC') }

    before do
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
      Gitlab::CurrentSettings.expire_current_application_settings
    end

    context 'when enabled with valid values' do
      it 'persists the managed values to the application settings' do
        described_class.apply!

        expect(settings.reload.sidekiq_timezone_override).to eq('Europe/London')
      end
    end

    context 'when the config file is absent' do
      let(:fixture_file) { fixture('does_not_exist.yml') }

      it 'does not change the settings' do
        described_class.apply!

        expect(settings.reload.sidekiq_timezone_override).to eq('UTC')
      end
    end

    context 'when the database is not ready' do
      before do
        allow(described_class).to receive(:database_ready?).and_return(false)
      end

      it 'does not raise or change the settings' do
        expect { described_class.apply! }.not_to raise_error
        expect(settings.reload.sidekiq_timezone_override).to eq('UTC')
      end
    end

    context 'when a recognized column has an invalid value' do
      let(:fixture_file) { fixture('invalid_value.yml') }

      it 'raises and does not persist' do
        expect { described_class.apply! }.to raise_error(described_class::InvalidConfigurationError)
        expect(settings.reload.sidekiq_timezone_override).to eq('UTC')
      end
    end
  end

  describe '.reset!' do
    it 're-reads the file after reset' do
      expect(described_class.all).to eq(sidekiq_timezone_override: 'Europe/London')

      stub_const("#{described_class}::PATH", fixture('empty.yml'))
      expect(described_class.all).to eq(sidekiq_timezone_override: 'Europe/London')

      described_class.reset!
      expect(described_class.all).to eq({})
    end
  end
end
