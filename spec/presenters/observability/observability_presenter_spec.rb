# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Observability::ObservabilityPresenter, feature_category: :observability do
  let(:group) { build_stubbed(:group) }
  let(:path) { 'services' }
  let(:presenter) { described_class.new(group, path) }

  let!(:observability_setting) do
    build_stubbed(:observability_group_o11y_setting,
      group: group,
      o11y_service_url: 'https://observability.example.com')
  end

  before do
    allow(group).to receive(:observability_group_o11y_setting).and_return(observability_setting)
    allow(Observability::O11yToken).to receive(:generate_tokens)
      .with(any_args)
      .and_return({ 'testToken' => 'value' })
  end

  describe '#title' do
    context 'with a valid path' do
      it 'returns the correct title' do
        expect(presenter.title).to eq('Observability|Services')
      end
    end

    context 'with an invalid path' do
      let(:path) { 'invalid-path' }

      it 'returns the default title' do
        expect(presenter.title).to eq('Observability')
      end
    end

    context 'with different valid paths' do
      described_class::PATHS.each do |path_key, expected_title|
        context "with path #{path_key}" do
          let(:path) { path_key }

          it "returns #{expected_title}" do
            expect(presenter.title).to eq(expected_title)
          end
        end
      end
    end
  end

  describe '#auth_tokens' do
    it 'returns formatted auth tokens' do
      expect(presenter.auth_tokens).to eq({ 'test_token' => 'value' })
    end

    context 'when auth tokens are blank' do
      before do
        allow(Observability::O11yToken).to receive(:generate_tokens)
          .with(any_args)
          .and_return(nil)
      end

      it 'returns empty hash' do
        expect(presenter.auth_tokens).to eq({})
      end
    end

    context 'when Observability::O11yToken.generate_tokens raises an exception' do
      let(:exception) { StandardError.new('Token generation failed') }

      before do
        allow(Observability::O11yToken).to receive(:generate_tokens)
          .with(any_args)
          .and_raise(exception)
        allow(Gitlab::ErrorTracking).to receive(:log_exception)
      end

      it 'returns empty hash and logs the exception' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(exception)
        expect(presenter.auth_tokens).to eq({})
      end
    end
  end

  describe '#url_with_path' do
    it 'returns a URI with the observability service URL and path' do
      result = presenter.url_with_path

      expect(result).to be_a(URI::HTTPS)
      expect(result.to_s).to eq('https://observability.example.com/services')
    end

    context 'with different paths' do
      let(:path) { 'traces-explorer' }

      it 'joins the service URL with the specified path' do
        result = presenter.url_with_path

        expect(result.to_s).to eq('https://observability.example.com/traces-explorer')
      end
    end

    context 'when group has no observability settings' do
      let(:group_without_settings) { build_stubbed(:group) }
      let(:presenter_without_settings) { described_class.new(group_without_settings, path) }

      before do
        allow(group_without_settings).to receive(:observability_group_o11y_setting).and_return(nil)
      end

      it 'returns nil' do
        result = presenter_without_settings.url_with_path

        expect(result).to be_nil
      end
    end

    context 'when observability setting has no service URL' do
      let!(:observability_setting_without_url) do
        build_stubbed(:observability_group_o11y_setting,
          group: group,
          o11y_service_url: nil)
      end

      before do
        allow(group).to receive(:observability_group_o11y_setting).and_return(observability_setting_without_url)
      end

      it 'returns nil' do
        result = presenter.url_with_path

        expect(result).to be_nil
      end
    end
  end

  describe '#provisioning?' do
    context 'when auth_tokens status is :provisioning' do
      before do
        allow(Observability::O11yToken).to receive(:generate_tokens)
          .with(any_args)
          .and_return({ 'status' => :provisioning })
      end

      it { expect(presenter.provisioning?).to be true }
    end

    context 'when auth_tokens status is not :provisioning' do
      before do
        allow(Observability::O11yToken).to receive(:generate_tokens)
          .with(any_args)
          .and_return({ 'status' => :ready })
      end

      it { expect(presenter.provisioning?).to be false }
    end

    context 'when auth_tokens is nil, empty, or has no status key' do
      where(:tokens) do
        [
          nil,
          {},
          { 'token' => 'value' },
          { 'status' => 'provisioning' } # string, not symbol
        ]
      end

      with_them do
        before do
          allow(Observability::O11yToken).to receive(:generate_tokens)
            .with(any_args)
            .and_return(tokens)
        end

        it { expect(presenter.provisioning?).to be false }
      end
    end

    context 'when group has no observability settings' do
      let(:group_without_settings) { build_stubbed(:group) }
      let(:presenter_without_settings) { described_class.new(group_without_settings, path) }

      before do
        allow(group_without_settings).to receive(:observability_group_o11y_setting).and_return(nil)
      end

      it { expect(presenter_without_settings.provisioning?).to be false }
    end

    context 'when token generation raises an exception' do
      before do
        allow(Observability::O11yToken).to receive(:generate_tokens)
          .with(any_args)
          .and_raise(StandardError.new('Token generation failed'))
        allow(Gitlab::ErrorTracking).to receive(:log_exception)
      end

      it { expect(presenter.provisioning?).to be false }
    end
  end

  describe '#to_h' do
    it 'returns a hash with all required keys' do
      result = presenter.to_h

      expect(result).to include(
        o11y_url: 'https://observability.example.com',
        path: 'services',
        auth_tokens: { 'test_token' => 'value' },
        title: 'Observability|Services'
      )
    end

    context 'when group has no observability settings' do
      let(:group_without_settings) { build_stubbed(:group) }
      let(:presenter_without_settings) { described_class.new(group_without_settings, path) }

      before do
        allow(group_without_settings).to receive(:observability_group_o11y_setting).and_return(nil)
      end

      it 'returns nil values for observability-specific fields' do
        result = presenter_without_settings.to_h

        expect(result).to include(
          o11y_url: nil,
          path: 'services',
          auth_tokens: {},
          title: 'Observability|Services'
        )
      end
    end

    context 'when auth tokens are blank' do
      before do
        allow(Observability::O11yToken).to receive(:generate_tokens)
          .with(any_args)
          .and_return(nil)
      end

      it 'returns empty hash for auth_tokens' do
        result = presenter.to_h

        expect(result[:auth_tokens]).to eq({})
      end
    end

    context 'when auth tokens have camelCase keys' do
      before do
        allow(Observability::O11yToken).to receive(:generate_tokens)
          .with(any_args)
          .and_return({ 'testToken' => 'value', 'anotherKey' => 'another_value' })
      end

      it 'transforms keys to snake_case' do
        result = presenter.to_h

        expect(result[:auth_tokens]).to eq({
          'test_token' => 'value',
          'another_key' => 'another_value'
        })
      end
    end
  end
end
