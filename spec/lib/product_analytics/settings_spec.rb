# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductAnalytics::Settings, feature_category: :product_analytics do
  describe 'config settings' do
    context 'when configured' do
      before do
        mock_settings('test')
      end

      it 'will be configured' do
        expect(described_class.configured?).to be_truthy
      end
    end

    context 'when not configured' do
      before do
        mock_settings('')
      end

      it 'will not be configured' do
        expect(described_class.configured?).to be_falsey
      end
    end

    context 'when one configuration setting is missing' do
      before do
        missing_key = ProductAnalytics::Settings::CONFIG_KEYS.last
        mock_settings('test', ProductAnalytics::Settings::CONFIG_KEYS - [missing_key])
        allow(::Gitlab::CurrentSettings).to receive(missing_key).and_return('')
      end

      it 'will not be configured' do
        expect(described_class.configured?).to be_falsey
      end
    end

    ProductAnalytics::Settings::CONFIG_KEYS.each do |key|
      it "can read #{key}" do
        expect(::Gitlab::CurrentSettings).to receive(key).and_return('test')

        expect(described_class.send(key)).to eq('test')
      end
    end
  end

  describe '.enabled?' do
    before do
      allow(described_class).to receive(:configured?).and_return(true)
    end

    context 'when enabled' do
      before do
        allow(::Gitlab::CurrentSettings).to receive(:product_analytics_enabled?).and_return(true)
      end

      it 'will be enabled' do
        expect(described_class.enabled?).to be_truthy
      end
    end

    context 'when disabled' do
      before do
        allow(::Gitlab::CurrentSettings).to receive(:product_analytics_enabled?).and_return(false)
      end

      it 'will be enabled' do
        expect(described_class.enabled?).to be_falsey
      end
    end
  end

  private

  def mock_settings(setting, keys = ProductAnalytics::Settings::CONFIG_KEYS)
    keys.each do |key|
      allow(::Gitlab::CurrentSettings).to receive(key).and_return(setting)
    end
  end
end
