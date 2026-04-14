# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Observability::ObservabilityPresenter, :use_clean_rails_memory_store_caching, feature_category: :observability do
  include ExclusiveLeaseHelpers
  include ReactiveCachingHelpers

  let(:group) { build_stubbed(:group) }
  let(:path) { 'services' }
  let(:presenter) { described_class.new(group, path) }

  let!(:observability_setting) do
    build_stubbed(:observability_group_o11y_setting,
      group: group,
      o11y_service_url: 'https://observability.example.com')
  end

  before do
    stub_reactive_cache
    allow(group).to receive(:observability_group_o11y_setting).and_return(observability_setting)
    allow(Observability::O11yToken).to receive(:generate_tokens)
      .with(any_args)
      .and_return({ 'testToken' => 'value' })
  end

  describe '.valid_path?' do
    where(:path, :valid) do
      [
        ['alerts',                               true],
        ['not-a-real-path',                      false],
        ['metrics-explorer',                     false],
        ['infrastructure-monitoring',            false],
        ['dashboard/my-board',                   true],
        ['dashboard/my-board/my-widget',         true],
        ['trace/abc123',                         true],
        ['services/my-svc',                      true],
        ['services/my-svc/top-level-operations', true],
        ['dashboard/a/b/c',                      false],
        ['alerts/../admin',                      false],
        ['trace/test.service',                   true],
        ['services/my@svc',                      false],
        ['services/my svc',                      false]
      ]
    end

    with_them do
      it { expect(described_class.valid_path?(path)).to be(valid) }
    end
  end

  describe '#title' do
    it 'returns the default title for an unknown path' do
      expect(described_class.new(group, 'invalid-path').title).to eq('Observability')
    end

    it 'inherits the top-level title for a sub-path' do
      expect(described_class.new(group, 'alerts/edit').title).to eq('Observability|Alerts')
    end

    context 'with every defined PATHS entry' do
      described_class::PATHS.each do |path|
        expected_title = described_class::SEGMENT_TITLES.fetch(path.split('/').first, 'Observability')
        it "returns '#{expected_title}' for path '#{path}'" do
          expect(described_class.new(group, path).title).to eq(expected_title)
        end
      end
    end
  end

  describe '#auth_tokens' do
    context 'when cache is empty' do
      it 'returns empty hash and enqueues worker' do
        expect(ExternalServiceReactiveCachingWorker).to receive(:perform_async)
          .with(described_class.name, group.id)

        expect(presenter.auth_tokens).to eq({})
        expect(reactive_cache_alive?(presenter)).to be_truthy
      end
    end

    context 'when cache is populated' do
      let(:cached_tokens) { { 'test_token' => 'value' } }

      before do
        stub_reactive_cache(presenter, cached_tokens)
      end

      context 'when cache is populated' do
        let(:cached_tokens) { { 'test_token' => 'value' } }

        before do
          stub_reactive_cache(presenter, cached_tokens)
        end

        it 'returns cached tokens without enqueuing worker' do
          expect(ExternalServiceReactiveCachingWorker).not_to receive(:perform_async)
          expect(presenter.auth_tokens).to eq(cached_tokens)
        end
      end
    end

    context 'when cache is expired' do
      before do
        stub_reactive_cache(presenter, { 'test_token' => 'value' })
        invalidate_reactive_cache(presenter)
      end

      it 'returns empty hash and enqueues worker' do
        expect(ExternalServiceReactiveCachingWorker).to receive(:perform_async)
          .with(described_class.name, group.id)

        expect(presenter.auth_tokens).to eq({})
      end
    end

    context 'when observability_setting is nil' do
      let(:group_without_settings) { build_stubbed(:group) }
      let(:presenter_without_settings) { described_class.new(group_without_settings, path) }

      before do
        allow(group_without_settings).to receive(:observability_group_o11y_setting).and_return(nil)
      end

      it 'returns empty hash without enqueuing worker' do
        expect(ExternalServiceReactiveCachingWorker).not_to receive(:perform_async)

        expect(presenter_without_settings.auth_tokens).to eq({})
      end
    end
  end

  describe '#url_with_path' do
    it 'returns a URI joining the service URL and path' do
      result = presenter.url_with_path

      expect(result).to be_a(URI::HTTPS)
      expect(result.to_s).to eq('https://observability.example.com/services')
    end

    context 'when group has no observability settings' do
      before do
        allow(group).to receive(:observability_group_o11y_setting).and_return(nil)
      end

      it 'returns nil' do
        expect(presenter.url_with_path).to be_nil
      end
    end

    context 'when observability setting has no service URL' do
      before do
        setting_without_url = build_stubbed(:observability_group_o11y_setting, group: group, o11y_service_url: nil)
        allow(group).to receive(:observability_group_o11y_setting).and_return(setting_without_url)
      end

      it 'returns nil' do
        expect(presenter.url_with_path).to be_nil
      end
    end
  end

  describe '#provisioning?' do
    context 'when auth_tokens status is :provisioning' do
      before do
        stub_reactive_cache(presenter, { 'status' => :provisioning })
      end

      it { expect(presenter.provisioning?).to be true }
    end

    context 'when auth_tokens status is not :provisioning or missing' do
      where(:tokens) do
        [
          nil,
          {},
          { 'status' => :ready },
          { 'token' => 'value' },
          { 'status' => 'provisioning' } # string, not symbol
        ]
      end

      with_them do
        before do
          stub_reactive_cache(presenter, tokens)
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

    context 'when cache is empty' do
      it { expect(presenter.provisioning?).to be false }
    end
  end

  describe 'ReactiveCaching' do
    describe 'configuration' do
      it 'configures reactive caching correctly' do
        expect(described_class.included_modules).to include(ReactiveCaching)
        expect(described_class.reactive_cache_key).to be_a(Proc)
        expect(described_class.reactive_cache_key.call(presenter)).to match_array(['observability_presenter', group.id])
        expect(described_class.reactive_cache_refresh_interval).to eq(30.seconds)
        expect(described_class.reactive_cache_lifetime).to eq(10.minutes)
        expect(described_class.reactive_cache_work_type).to eq(:external_dependency)
        expect(described_class.reactive_cache_worker_finder).to be_a(Proc)
      end
    end

    describe '#id' do
      it 'returns the group id' do
        expect(presenter.id).to eq(group.id)
      end
    end

    describe '.reactive_cache_worker_finder' do
      let(:group_id) { group.id }
      let(:found_group) { instance_double(Group, id: group_id) }

      context 'when group exists' do
        before do
          allow(Group).to receive(:id_in).with([group_id]).and_return(instance_double(ActiveRecord::Relation,
            first: found_group))
        end

        it 'reconstructs presenter from group id' do
          result = described_class.reactive_cache_worker_finder.call(group_id)

          expect(result).to be_a(described_class)
          expect(result.id).to eq(group_id)
          expect(result.instance_variable_get(:@group)).to eq(found_group)
          expect(result.instance_variable_get(:@path)).to be_nil
        end
      end

      context 'when group does not exist' do
        before do
          allow(Group).to receive(:id_in).with([group_id]).and_return(instance_double(ActiveRecord::Relation,
            first: nil))
        end

        it 'returns nil' do
          result = described_class.reactive_cache_worker_finder.call(group_id)

          expect(result).to be_nil
        end
      end
    end

    describe '#calculate_reactive_cache' do
      let(:tokens) { { 'testToken' => 'value', 'anotherKey' => 'another_value' } }
      let(:expected_result) { { 'test_token' => 'value', 'another_key' => 'another_value' } }

      before do
        allow(Observability::O11yToken).to receive(:generate_tokens)
          .with(observability_setting)
          .and_return(tokens)
      end

      it 'generates and transforms tokens' do
        expect(presenter.calculate_reactive_cache).to eq(expected_result)
        expect(Observability::O11yToken).to have_received(:generate_tokens).with(observability_setting)
      end

      context 'when observability_setting is nil' do
        let(:group_without_settings) { build_stubbed(:group) }
        let(:presenter_without_settings) { described_class.new(group_without_settings, path) }

        before do
          allow(group_without_settings).to receive(:observability_group_o11y_setting).and_return(nil)
        end

        it 'returns empty hash without calling generate_tokens' do
          expect(Observability::O11yToken).not_to receive(:generate_tokens)

          expect(presenter_without_settings.calculate_reactive_cache).to eq({})
        end
      end

      context 'when generate_tokens returns nil' do
        before do
          allow(Observability::O11yToken).to receive(:generate_tokens)
            .with(observability_setting)
            .and_return(nil)
        end

        it 'returns empty hash' do
          expect(presenter.calculate_reactive_cache).to eq({})
        end
      end

      context 'when token generation raises an exception' do
        let(:exception) { StandardError.new('Token generation failed') }

        before do
          allow(Observability::O11yToken).to receive(:generate_tokens)
            .with(observability_setting)
            .and_raise(exception)
          allow(Gitlab::ErrorTracking).to receive(:log_exception)
        end

        it 'returns empty hash and logs the exception' do
          expect(presenter.calculate_reactive_cache).to eq({})
          expect(Gitlab::ErrorTracking).to have_received(:log_exception).with(exception)
        end
      end

      context 'when tokens have camelCase keys' do
        let(:camel_case_tokens) { { 'testToken' => 'value', 'anotherKey' => 'another_value' } }
        let(:expected_result) { { 'test_token' => 'value', 'another_key' => 'another_value' } }

        before do
          allow(Observability::O11yToken).to receive(:generate_tokens)
            .with(observability_setting)
            .and_return(camel_case_tokens)
        end

        it 'transforms keys to snake_case' do
          expect(presenter.calculate_reactive_cache).to eq(expected_result)
        end
      end
    end

    describe '#exclusively_update_reactive_cache!' do
      let(:tokens) { { 'testToken' => 'value' } }
      let(:expected_result) { { 'test_token' => 'value' } }
      let(:cache_key) { reactive_cache_key(presenter) }

      before do
        stub_reactive_cache(presenter, 'preexisting')
        stub_exclusive_lease(cache_key)
        allow(Observability::O11yToken).to receive(:generate_tokens)
          .with(observability_setting)
          .and_return(tokens)
      end

      it 'caches the result and enqueues repeat worker' do
        expect_reactive_cache_update_queued(presenter, worker_klass: ExternalServiceReactiveCachingWorker)

        presenter.exclusively_update_reactive_cache!

        expect(read_reactive_cache(presenter)).to eq(expected_result)
      end
    end
  end

  describe '#to_h' do
    context 'when cache is populated' do
      let(:cached_tokens) { { 'test_token' => 'value' } }

      before do
        stub_reactive_cache(presenter, cached_tokens)
      end

      it 'returns a hash with all required keys' do
        expect(presenter.to_h).to include(
          o11y_url: 'https://observability.example.com',
          path: 'services',
          auth_tokens: cached_tokens,
          title: 'Observability|Services',
          query_params: {}
        )
      end
    end

    context 'when cache is empty' do
      it 'returns a hash with empty auth_tokens' do
        expect(presenter.to_h).to include(
          o11y_url: 'https://observability.example.com',
          path: 'services',
          auth_tokens: {},
          title: 'Observability|Services',
          query_params: {}
        )
      end
    end

    context 'when query_params are provided' do
      let(:presenter) { described_class.new(group, path, query_params: { 'ruleId' => 'abc-123' }) }

      it 'includes them in the hash' do
        expect(presenter.to_h[:query_params]).to eq({ 'ruleId' => 'abc-123' })
      end
    end

    context 'when group has no observability settings' do
      let(:group_without_settings) { build_stubbed(:group) }
      let(:presenter_without_settings) { described_class.new(group_without_settings, path) }

      before do
        allow(group).to receive(:observability_group_o11y_setting).and_return(nil)
      end

      it 'returns nil values for observability-specific fields' do
        expect(presenter_without_settings.to_h).to include(
          o11y_url: nil,
          path: 'services',
          auth_tokens: {},
          title: 'Observability|Services'
        )
      end
    end
  end
end
