# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductAnalytics::Settings, feature_category: :product_analytics do
  let_it_be(:project) { create(:project) }

  subject { described_class.for_project(project) }

  describe 'config settings' do
    context 'when configured' do
      before do
        mock_settings('test')
      end

      it 'will be configured' do
        expect(subject.configured?).to be_truthy
      end
    end

    context 'when not configured' do
      before do
        mock_settings('')
      end

      it 'will not be configured' do
        expect(subject.configured?).to be_falsey
      end
    end

    context 'when one configuration setting is missing' do
      before do
        missing_key = ProductAnalytics::Settings::ALL_CONFIG_KEYS.last
        mock_settings('test', ProductAnalytics::Settings::ALL_CONFIG_KEYS - [missing_key])
        allow(::Gitlab::CurrentSettings).to receive(missing_key).and_return('')
      end

      it 'will not be configured' do
        expect(subject.configured?).to be_falsey
      end
    end

    ProductAnalytics::Settings::ALL_CONFIG_KEYS.each do |key|
      it "can read #{key}" do
        expect(::Gitlab::CurrentSettings).to receive(key).and_return('test')

        expect(subject.send(key)).to eq('test')
      end

      context 'with project' do
        it "will override when provided a project #{key}" do
          expect(::Gitlab::CurrentSettings).not_to receive(key)
          expect(project.project_setting).to receive(key).and_return('test')

          expect(subject.send(key)).to eq('test')
        end

        it "will will not override when provided a blank project #{key}" do
          expect(::Gitlab::CurrentSettings).to receive(key).and_return('test')
          expect(project.project_setting).to receive(key).and_return('')

          expect(subject.send(key)).to eq('test')
        end
      end
    end
  end

  describe '.enabled?' do
    before do
      allow(subject).to receive(:configured?).and_return(true)
    end

    context 'when enabled' do
      before do
        allow(::Gitlab::CurrentSettings).to receive(:product_analytics_enabled?).and_return(true)
      end

      it 'will be enabled' do
        expect(subject.enabled?).to be_truthy
      end
    end

    context 'when disabled' do
      before do
        allow(::Gitlab::CurrentSettings).to receive(:product_analytics_enabled?).and_return(false)
      end

      it 'will be enabled' do
        expect(subject.enabled?).to be_falsey
      end
    end
  end

  private

  def mock_settings(setting, keys = ProductAnalytics::Settings::ALL_CONFIG_KEYS)
    keys.each do |key|
      allow(::Gitlab::CurrentSettings).to receive(key).and_return(setting)
    end
  end
end
