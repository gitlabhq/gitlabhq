# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Feature, :clean_gitlab_redis_feature_flag, stub_feature_flags: false, feature_category: :shared do
  include StubVersion

  # Pick a long-lasting real feature flag to test that we can check feature flags in the load balancer
  let(:load_balancer_test_feature_flag) { :require_email_verification }

  def wrap_all_methods_with_flag_check(lb, flag)
    lb.methods(false).each do |meth|
      allow(lb).to receive(meth).and_wrap_original do |m, *args, **kwargs, &block|
        Feature.enabled?(flag)
        m.call(*args, **kwargs, &block)
      end
    end
  end
  before do
    wrap_all_methods_with_flag_check(ApplicationRecord.load_balancer, load_balancer_test_feature_flag)

    # reset Flipper AR-engine
    Feature.reset # rubocop:disable RSpec/DescribedClass -- in a nested group described_class becomes Feature::Target
  end

  describe '.current_request' do
    it 'returns a FlipperRequest with a flipper_id' do
      flipper_request = described_class.current_request

      expect(flipper_request.flipper_id).to include("FlipperRequest:")
    end

    context 'when request store is inactive' do
      it 'does not cache flipper_id' do
        previous_id = described_class.current_request.flipper_id

        expect(described_class.current_request.flipper_id).not_to eq(previous_id)
      end
    end

    context 'when request store is active', :request_store do
      it 'caches flipper_id when request store is active' do
        previous_id = described_class.current_request.flipper_id

        expect(described_class.current_request.flipper_id).to eq(previous_id)
      end

      it 'returns a new flipper_id when request ends' do
        previous_id = described_class.current_request.flipper_id

        RequestStore.end!

        expect(described_class.current_request.flipper_id).not_to eq(previous_id)
      end
    end
  end

  describe '.current_pod' do
    it 'returns a FlipperPod with a flipper_id' do
      expect(described_class.current_pod).to respond_to(:flipper_id)
    end

    it 'is the same flipper_id within a process' do
      previous_id = described_class.current_pod.flipper_id

      expect(previous_id).to eq(described_class.current_pod.flipper_id)
    end

    it 'is a different flipper_id in a new host' do
      previous_id = described_class.current_pod.flipper_id

      # Simulate a new process by changing host,
      previous_host = Socket.gethostname
      allow(Socket).to receive(:gethostname).and_return("#{previous_host}-1")

      new_id = Feature::FlipperPod.new.flipper_id # Bypass caching
      expect(previous_id).not_to eq(new_id)
    end
  end

  describe '.gitlab_instance' do
    it 'returns a FlipperGitlabInstance with a flipper_id' do
      flipper_request = described_class.gitlab_instance

      expect(flipper_request.flipper_id).to include("FlipperGitlabInstance:")
    end

    it 'caches flipper_id' do
      previous_id = described_class.gitlab_instance.flipper_id

      expect(described_class.gitlab_instance.flipper_id).to eq(previous_id)
    end
  end

  describe '.get' do
    let(:feature) { double(:feature) }
    let(:key) { 'my_feature' }

    it 'returns the Flipper feature' do
      expect_any_instance_of(Flipper::DSL).to receive(:feature).with(key)
                                                               .and_return(feature)

      expect(described_class.get(key)).to eq(feature)
    end
  end

  describe '.persisted_names' do
    it 'returns the names of the persisted features' do
      described_class.enable('foo')

      expect(described_class.persisted_names).to contain_exactly('foo')
    end

    it 'returns an empty Array when no features are presisted' do
      expect(described_class.persisted_names).to be_empty
    end

    it 'caches the feature names when request store is active',
      :request_store, :use_clean_rails_memory_store_caching do
        described_class.enable('foo')

        expect(Gitlab::ProcessMemoryCache.cache_backend)
          .to receive(:fetch)
            .once
            .with('flipper/v1/features', { expires_in: 1.minute })
            .and_call_original

        2.times do
          expect(described_class.persisted_names).to contain_exactly('foo')
        end
      end

    it 'fetches all flags once in a single query', :request_store do
      described_class.enable('foo1')
      described_class.enable('foo2')

      queries = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        expect(described_class.persisted_names).to contain_exactly('foo1', 'foo2')

        RequestStore.clear!

        expect(described_class.persisted_names).to contain_exactly('foo1', 'foo2')
      end

      expect(queries.count).to eq(1)
    end
  end

  describe '.persisted_name?' do
    context 'when the feature is persisted' do
      it 'returns true when feature name is a string' do
        described_class.enable('foo')

        expect(described_class.persisted_name?('foo')).to eq(true)
      end

      it 'returns true when feature name is a symbol' do
        described_class.enable('foo')

        expect(described_class.persisted_name?(:foo)).to eq(true)
      end
    end

    context 'when the feature is not persisted' do
      it 'returns false when feature name is a string' do
        expect(described_class.persisted_name?('foo')).to eq(false)
      end

      it 'returns false when feature name is a symbol' do
        expect(described_class.persisted_name?(:bar)).to eq(false)
      end
    end
  end

  describe '.all' do
    let(:features) { Set.new }

    it 'returns the Flipper features as an array' do
      expect_any_instance_of(Flipper::DSL).to receive(:features)
                                                .and_return(features)

      expect(described_class.all).to eq(features.to_a)
    end
  end

  describe '.flipper' do
    context 'when request store is inactive' do
      it 'memoizes the Flipper instance but does not not enable Flipper memoization' do
        expect(Flipper).to receive(:new).once.and_call_original

        2.times do
          described_class.flipper
        end

        expect(described_class.flipper.adapter.memoizing?).to eq(false)
      end
    end

    context 'when request store is active', :request_store do
      it 'memoizes the Flipper instance' do
        expect(Flipper).to receive(:new).once.and_call_original

        described_class.flipper
        described_class.instance_variable_set(:@flipper, nil)
        described_class.flipper

        expect(described_class.flipper.adapter.memoizing?).to eq(true)
      end
    end
  end

  describe '.enabled?' do
    before do
      allow(described_class).to receive(:log_feature_flag_states?).and_return(false)

      stub_feature_flag_definition(:disabled_feature_flag)
      stub_feature_flag_definition(:enabled_feature_flag, default_enabled: true)
    end

    context 'when using redis cache', :use_clean_rails_redis_caching do
      it 'does not make recursive feature-flag calls' do
        expect(described_class).to receive(:enabled?).once.and_call_original
        described_class.enabled?(:disabled_feature_flag)
      end
    end

    context 'when self-recursive' do
      before do
        allow(Feature).to receive(:with_feature).and_wrap_original do |original, name, &block|
          original.call(name) do |ff|
            Feature.enabled?(name)
            block.call(ff)
          end
        end
      end

      it 'returns the default value' do
        expect(described_class.enabled?(:enabled_feature_flag)).to eq true
      end

      it 'detects self recursion' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception)
                .with(have_attributes(message: 'self recursion'), { stack: [:enabled_feature_flag] })

        described_class.enabled?(:enabled_feature_flag)
      end
    end

    context 'when deeply recursive' do
      before do
        allow(Feature).to receive(:with_feature).and_wrap_original do |original, name, &block|
          original.call(name) do |ff|
            Feature.enabled?(:"deeper_#{name}", type: :undefined, default_enabled_if_undefined: true)
            block.call(ff)
          end
        end
      end

      it 'detects deep recursion' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception)
                .with(have_attributes(message: 'deep recursion'), stack: have_attributes(size: be > 10))

        described_class.enabled?(:enabled_feature_flag)
      end
    end

    it 'returns false (and tracks / raises exception for dev) for undefined feature' do
      expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

      expect(described_class.enabled?(:some_random_feature_fla, type: :undefined)).to be_falsey
    end

    it 'returns false for undefined feature with default_enabled_if_undefined: false' do
      expect(described_class.enabled?(:some_random_feature_flag, type: :undefined, default_enabled_if_undefined: false)).to be_falsey
    end

    it 'returns true for undefined feature with default_enabled_if_undefined: true' do
      expect(described_class.enabled?(:some_random_feature_flag, type: :undefined, default_enabled_if_undefined: true)).to be_truthy
    end

    it 'returns false for existing disabled feature in the database' do
      described_class.disable(:disabled_feature_flag)

      expect(described_class.enabled?(:disabled_feature_flag)).to be_falsey
    end

    it 'returns true for existing enabled feature in the database' do
      described_class.enable(:enabled_feature_flag)

      expect(described_class.enabled?(:enabled_feature_flag)).to be_truthy
    end

    it { expect(described_class.send(:l1_cache_backend)).to eq(Gitlab::ProcessMemoryCache.cache_backend) }
    it { expect(described_class.send(:l2_cache_backend)).to eq(Gitlab::Redis::FeatureFlag.cache_store) }

    it 'caches the status in L1 and L2 caches',
      :request_store, :use_clean_rails_memory_store_caching do
        described_class.enable(:disabled_feature_flag)
        flipper_key = "flipper/v1/feature/disabled_feature_flag"

        expect(described_class.send(:l2_cache_backend))
          .to receive(:fetch)
            .once
            .with(flipper_key, { expires_in: 1.hour })
            .and_call_original

        expect(described_class.send(:l1_cache_backend))
          .to receive(:fetch)
            .once
            .with(flipper_key, { expires_in: 1.minute })
            .and_call_original

        2.times do
          expect(described_class.enabled?(:disabled_feature_flag)).to be_truthy
        end
      end

    it 'returns the default value when the database does not exist' do
      fake_default = double('fake default')

      base_class = Feature::FlipperRecord
      expect(base_class).to receive(:connection) { raise ActiveRecord::NoDatabaseError, "No database" }

      expect(described_class.enabled?(:a_feature, type: :undefined, default_enabled_if_undefined: fake_default)).to eq(fake_default)
    end

    context 'logging is enabled', :request_store do
      before do
        allow(described_class).to receive(:log_feature_flag_states?).and_call_original

        stub_feature_flag_definition(:enabled_feature_flag, log_state_changes: true)

        described_class.enable(:feature_flag_state_logs)
        described_class.enable(:enabled_feature_flag)
        described_class.enabled?(:enabled_feature_flag)
      end

      it 'does not log feature_flag_state_logs' do
        expect(described_class.logged_states).not_to have_key("feature_flag_state_logs")
      end

      it 'logs other feature flags' do
        expect(described_class.logged_states).to have_key(:enabled_feature_flag)
        expect(described_class.logged_states[:enabled_feature_flag]).to be_truthy
      end
    end

    context 'cached feature flag', :request_store do
      before do
        described_class.send(:flipper).memoize = false
        described_class.enabled?(:disabled_feature_flag)
      end

      it 'caches the status in L1 cache for the first minute' do
        expect do
          expect(described_class.send(:l1_cache_backend)).to receive(:fetch).once.and_call_original
          expect(described_class.send(:l2_cache_backend)).not_to receive(:fetch)
          expect(described_class.enabled?(:disabled_feature_flag)).to be_truthy
        end.not_to exceed_query_limit(0)
      end

      it 'caches the status in L2 cache after 2 minutes' do
        travel_to 2.minutes.from_now do
          expect do
            expect(described_class.send(:l1_cache_backend)).to receive(:fetch).once.and_call_original
            expect(described_class.send(:l2_cache_backend)).to receive(:fetch).once.and_call_original
            expect(described_class.enabled?(:disabled_feature_flag)).to be_truthy
          end.not_to exceed_query_limit(0)
        end
      end

      it 'fetches the status after an hour' do
        travel_to 61.minutes.from_now do
          expect do
            expect(described_class.send(:l1_cache_backend)).to receive(:fetch).once.and_call_original
            expect(described_class.send(:l2_cache_backend)).to receive(:fetch).once.and_call_original
            expect(described_class.enabled?(:disabled_feature_flag)).to be_truthy
          end.not_to exceed_query_limit(1)
        end
      end
    end

    [:current_request, :request, described_class.current_request].each do |thing|
      context "with #{thing} actor" do
        context 'when request store is inactive' do
          it 'returns the approximate percentage set' do
            number_of_times = 1_000
            percentage = 50
            described_class.enable_percentage_of_actors(:enabled_feature_flag, percentage)

            gate_values = Array.new(number_of_times) do
              described_class.enabled?(:enabled_feature_flag, thing)
            end

            margin_of_error = 0.07 * number_of_times
            expected_size = number_of_times * percentage / 100
            expect(gate_values.count { |v| v }).to be_within(margin_of_error).of(expected_size)
          end
        end

        context 'when request store is active', :request_store do
          it 'always returns the same gate value' do
            described_class.enable_percentage_of_actors(:enabled_feature_flag, 50)

            previous_gate_value = described_class.enabled?(:enabled_feature_flag, thing)

            1_000.times do
              expect(described_class.enabled?(:enabled_feature_flag, thing)).to eq(previous_gate_value)
            end
          end
        end
      end
    end

    context 'with gitlab_instance actor' do
      it 'always returns the same gate value' do
        described_class.enable(:enabled_feature_flag, described_class.gitlab_instance)

        expect(described_class.enabled?(:enabled_feature_flag, described_class.gitlab_instance)).to be_truthy
      end
    end

    context 'with :instance actor' do
      it 'always returns the same gate value' do
        described_class.enable(:enabled_feature_flag, :instance)

        expect(described_class.enabled?(:enabled_feature_flag, :instance)).to be_truthy
      end
    end

    context 'with :pod actor' do
      before do
        stub_feature_flag_definition(:enabled_feature_flag)
      end

      it 'returns the same value in the same host' do
        described_class.enable(:enabled_feature_flag, :current_pod)

        expect(described_class.enabled?(:enabled_feature_flag, :current_pod)).to be_truthy
      end

      it 'returns different values in different hosts' do
        number_of_times = 1_000
        percentage = 50
        described_class.enable_percentage_of_actors(:enabled_feature_flag, percentage)
        results = { true => 0, false => 0 }
        original_hostname = Socket.gethostname
        number_of_times.times do |i|
          allow(Socket).to receive(:gethostname).and_return("#{original_hostname}-#{i}")
          flipper_thing = Feature::FlipperPod.new # Create a new one to bypass caching, we are simulating many different pods
          result = described_class.enabled?(:enabled_feature_flag, flipper_thing)
          results[result] += 1
        end

        percent_true = (results[true].to_f / (results[true] + results[false])) * 100
        expect(percent_true).to be_within(5).of(percentage)
      end
    end

    context 'with a group member' do
      let(:key) { :awesome_feature }
      let(:guinea_pigs) { create_list(:user, 3) }

      before do
        described_class.reset
        stub_feature_flag_definition(key)
        Flipper.unregister_groups
        Flipper.register(:guinea_pigs) do |actor|
          guinea_pigs.include?(actor.thing)
        end
        described_class.enable(key, described_class.group(:guinea_pigs))
      end

      it 'is true for all group members' do
        expect(described_class.enabled?(key, guinea_pigs[0])).to be_truthy
        expect(described_class.enabled?(key, guinea_pigs[1])).to be_truthy
        expect(described_class.enabled?(key, guinea_pigs[2])).to be_truthy
      end

      it 'is false for any other actor' do
        expect(described_class.enabled?(key, create(:user))).to be_falsey
      end
    end

    context 'with an individual actor' do
      let(:actor) { stub_feature_flag_gate('CustomActor:5') }
      let(:another_actor) { stub_feature_flag_gate('CustomActor:10') }

      before do
        described_class.enable(:enabled_feature_flag, actor)
      end

      it 'returns true when same actor is informed' do
        expect(described_class.enabled?(:enabled_feature_flag, actor)).to be_truthy
      end

      it 'returns false when different actor is informed' do
        expect(described_class.enabled?(:enabled_feature_flag, another_actor)).to be_falsey
      end

      it 'returns false when no actor is informed' do
        expect(described_class.enabled?(:enabled_feature_flag)).to be_falsey
      end
    end

    context 'with invalid actor' do
      let(:actor) { double('invalid actor') }

      context 'when is dev_or_test_env' do
        it 'does raise exception' do
          expect { described_class.enabled?(:enabled_feature_flag, actor) }
            .to raise_error(/needs to include `FeatureGate` or implement `flipper_id`/)
        end
      end
    end

    context 'validates usage of feature flag with YAML definition' do
      let(:definition) do
        Feature::Definition.new(
          'development/my_feature_flag.yml',
          name: 'my_feature_flag',
          type: 'development',
          default_enabled: default_enabled
        ).tap(&:validate!)
      end

      let(:default_enabled) { false }

      before do
        stub_env('LAZILY_CREATE_FEATURE_FLAG', '0')
        lb_ff_definition = Feature::Definition.get(load_balancer_test_feature_flag)
        allow(Feature::Definition).to receive(:valid_usage!).and_call_original
        allow(Feature::Definition).to receive(:definitions) do
          { definition.key => definition, lb_ff_definition.key => lb_ff_definition }
        end
      end

      it 'when usage is correct' do
        expect { described_class.enabled?(:my_feature_flag) }.not_to raise_error
      end

      it 'when invalid type is used' do
        expect { described_class.enabled?(:my_feature_flag, type: :ops) }
          .to raise_error(/The given `type: :ops`/)
      end

      context 'when default_enabled: is false in the YAML definition' do
        it 'reads the default from the YAML definition' do
          expect(described_class.enabled?(:my_feature_flag)).to eq(default_enabled)
        end
      end

      context 'when default_enabled: is true in the YAML definition' do
        let(:default_enabled) { true }

        it 'reads the default from the YAML definition' do
          expect(described_class.enabled?(:my_feature_flag)).to eq(true)
        end

        context 'and feature has been disabled' do
          before do
            described_class.disable(:my_feature_flag)
          end

          it 'is not enabled' do
            expect(described_class.enabled?(:my_feature_flag)).to eq(false)
          end
        end

        context 'with a cached value and the YAML definition is changed thereafter' do
          before do
            described_class.enabled?(:my_feature_flag)
          end

          it 'reads new default value' do
            allow(definition).to receive(:default_enabled).and_return(true)

            expect(described_class.enabled?(:my_feature_flag)).to eq(true)
          end
        end

        context 'when YAML definition does not exist for an optional type' do
          let(:optional_type) { described_class::Shared::TYPES.find { |name, attrs| attrs[:optional] }.first }

          context 'when in dev or test environment' do
            it 'raises an error for dev' do
              expect { described_class.enabled?(:non_existent_flag, type: optional_type) }
                .to raise_error(
                  Feature::InvalidFeatureFlagError,
                  "The feature flag YAML definition for 'non_existent_flag' does not exist"
                )
            end
          end

          context 'when in production' do
            before do
              allow(Gitlab::ErrorTracking).to receive(:should_raise_for_dev?).and_return(false)
            end

            context 'when database exists' do
              before do
                allow(ApplicationRecord.database).to receive(:exists?).and_return(true)
              end

              it 'checks the persisted status and returns false' do
                expect(described_class).to receive(:with_feature).with(:non_existent_flag).and_call_original

                expect(described_class.enabled?(:non_existent_flag, type: optional_type)).to eq(false)
              end
            end

            context 'when database does not exist' do
              before do
                allow(ApplicationRecord.database).to receive(:exists?).and_return(false)
              end

              it 'returns false without checking the status in the database' do
                expect(described_class).not_to receive(:get)

                expect(described_class.enabled?(:non_existent_flag, type: optional_type)).to eq(false)
              end
            end
          end
        end
      end
    end
  end

  describe '.disabled?' do
    it 'returns true (and tracks / raises exception for dev) for undefined feature' do
      expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

      expect(described_class.disabled?(:some_random_feature_flag, type: :undefined)).to be_truthy
    end

    it 'returns true for undefined feature with default_enabled_if_undefined: false' do
      expect(described_class.disabled?(:some_random_feature_flag, type: :undefined, default_enabled_if_undefined: false)).to be_truthy
    end

    it 'returns false for undefined feature with default_enabled_if_undefined: true' do
      expect(described_class.disabled?(:some_random_feature_flag, type: :undefined, default_enabled_if_undefined: true)).to be_falsey
    end

    it 'returns true for existing disabled feature in the database' do
      stub_feature_flag_definition(:disabled_feature_flag)
      described_class.disable(:disabled_feature_flag)

      expect(described_class.disabled?(:disabled_feature_flag)).to be_truthy
    end

    it 'returns false for existing enabled feature in the database' do
      stub_feature_flag_definition(:enabled_feature_flag)
      described_class.enable(:enabled_feature_flag)

      expect(described_class.disabled?(:enabled_feature_flag)).to be_falsey
    end
  end

  shared_examples_for 'logging' do
    let(:expected_action) {}
    let(:expected_extra) {}

    it 'logs the event' do
      expect(described_class.logger).to receive(:info).at_least(:once).with(key: key, action: expected_action, **expected_extra)

      subject
    end
  end

  describe '.enable' do
    subject { described_class.enable(key, thing) }

    let(:key) { :awesome_feature }
    let(:thing) { true }

    it_behaves_like 'logging' do
      let(:expected_action) { :enable }
      let(:expected_extra) { { "extra.thing" => "true" } }
    end

    # This is documented to return true, modify doc/administration/feature_flags.md if it changes
    it 'returns true' do
      expect(subject).to be true
    end

    context 'when thing is an actor' do
      let(:thing) { create(:user) }

      it_behaves_like 'logging' do
        let(:expected_action) { eq(:enable) | eq(:remove_opt_out) }
        let(:expected_extra) { { "extra.thing" => thing.flipper_id.to_s } }
      end
    end
  end

  describe '.disable' do
    subject { described_class.disable(key, thing) }

    let(:key) { :awesome_feature }
    let(:thing) { false }

    it_behaves_like 'logging' do
      let(:expected_action) { :disable }
      let(:expected_extra) { { "extra.thing" => "false" } }
    end

    # This is documented to return true, modify doc/administration/feature_flags.md if it changes
    it 'returns true' do
      expect(subject).to be true
    end

    context 'when thing is an actor' do
      let(:thing) { create(:user) }
      let(:flag_opts) { {} }

      it_behaves_like 'logging' do
        let(:expected_action) { :disable }
        let(:expected_extra) { { "extra.thing" => thing.flipper_id.to_s } }
      end

      before do
        stub_feature_flag_definition(key, flag_opts)
      end

      context 'when the feature flag was enabled for this actor' do
        before do
          described_class.enable(key, thing)
        end

        it 'marks this thing as disabled' do
          expect { subject }.to change { thing_enabled? }.from(true).to(false)
        end

        it 'does not change the global value' do
          expect { subject }.not_to change { described_class.enabled?(key) }.from(false)
        end

        it 'is possible to re-enable the feature' do
          subject

          expect { described_class.enable(key, thing) }
            .to change { thing_enabled? }.from(false).to(true)
        end
      end

      context 'when the feature flag is enabled globally' do
        before do
          described_class.enable(key)
        end

        it 'does not mark this thing as disabled' do
          expect { subject }.not_to change { thing_enabled? }.from(true)
        end

        it 'does not change the global value' do
          expect { subject }.not_to change { described_class.enabled?(key) }.from(true)
        end
      end
    end
  end

  describe '.group_ids_for' do
    subject { described_class.group_ids_for(key) }

    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }

    let(:key) { :awesome_feature }

    it 'returns empty array' do
      expect(subject).to be_empty
    end

    context 'when group actor is enabled' do
      before do
        described_class.enable(key, group)
      end

      it 'returns the group id' do
        expect(subject).to eq([group.id.to_s])
      end
    end

    context 'when global flag is enabled' do
      before do
        described_class.enable(key)
      end

      it 'returns empty array' do
        expect(subject).to be_empty
      end
    end

    context 'when project actor is enabled' do
      before do
        described_class.enable(key, project)
      end

      it 'returns empty array' do
        expect(subject).to be_empty
      end
    end

    context 'when user actor is enabled' do
      before do
        described_class.enable(key, user)
      end

      it 'returns empty array' do
        expect(subject).to be_empty
      end
    end
  end

  describe 'opt_out' do
    subject { described_class.opt_out(key, thing) }

    let(:key) { :awesome_feature }

    before do
      stub_feature_flag_definition(key)
      described_class.enable(key)
    end

    context 'when thing is an actor' do
      let_it_be(:thing) { create(:project) }

      it 'marks this thing as disabled' do
        expect { subject }.to change { thing_enabled? }.from(true).to(false)
      end

      it 'does not change the global value' do
        expect { subject }.not_to change { described_class.enabled?(key) }.from(true)
      end

      it_behaves_like 'logging' do
        let(:expected_action) { eq(:opt_out) }
        let(:expected_extra) { { "extra.thing" => thing.flipper_id.to_s } }
      end

      it 'stores the opt-out information as a gate' do
        subject

        flag = described_class.get(key)

        expect(flag.actors_value).to include(include(thing.flipper_id))
        expect(flag.actors_value).not_to include(thing.flipper_id)
      end
    end

    context 'when thing is a group' do
      let(:thing) { described_class.group(:guinea_pigs) }
      let(:guinea_pigs) { create_list(:user, 3) }

      before do
        described_class.reset
        Flipper.unregister_groups
        Flipper.register(:guinea_pigs) do |actor|
          guinea_pigs.include?(actor.thing)
        end
      end

      it 'has no effect' do
        expect { subject }.not_to change { described_class.enabled?(key, guinea_pigs.first) }.from(true)
      end
    end
  end

  describe 'remove_opt_out' do
    subject { described_class.remove_opt_out(key, thing) }

    let(:key) { :awesome_feature }

    before do
      stub_feature_flag_definition(key)
      described_class.enable(key)
      described_class.opt_out(key, thing)
    end

    context 'when thing is an actor' do
      let_it_be(:thing) { create(:project) }

      it 're-enables this thing' do
        expect { subject }.to change { thing_enabled? }.from(false).to(true)
      end

      it 'does not change the global value' do
        expect { subject }.not_to change { described_class.enabled?(key) }.from(true)
      end

      it_behaves_like 'logging' do
        let(:expected_action) { eq(:remove_opt_out) }
        let(:expected_extra) { { "extra.thing" => thing.flipper_id.to_s } }
      end

      it 'removes the opt-out information' do
        subject

        flag = described_class.get(key)

        expect(flag.actors_value).to be_empty
      end
    end

    context 'when thing is a group' do
      let(:thing) { described_class.group(:guinea_pigs) }
      let(:guinea_pigs) { create_list(:user, 3) }

      before do
        described_class.reset
        Flipper.unregister_groups
        Flipper.register(:guinea_pigs) do |actor|
          guinea_pigs.include?(actor.thing)
        end
      end

      it 'has no effect' do
        expect { subject }.not_to change { described_class.enabled?(key, guinea_pigs.first) }.from(true)
      end
    end
  end

  describe '.enable_percentage_of_time' do
    subject { described_class.enable_percentage_of_time(key, percentage) }

    let(:key) { :awesome_feature }
    let(:percentage) { 50 }

    it_behaves_like 'logging' do
      let(:expected_action) { :enable_percentage_of_time }
      let(:expected_extra) { { "extra.percentage" => percentage.to_s } }
    end

    context 'when the flag is on' do
      before do
        described_class.enable(key)
      end

      it 'fails with InvalidOperation' do
        expect { subject }.to raise_error(described_class::InvalidOperation)
      end
    end
  end

  describe '.disable_percentage_of_time' do
    subject { described_class.disable_percentage_of_time(key) }

    let(:key) { :awesome_feature }

    it_behaves_like 'logging' do
      let(:expected_action) { :disable_percentage_of_time }
      let(:expected_extra) { {} }
    end
  end

  describe '.enable_percentage_of_actors' do
    subject { described_class.enable_percentage_of_actors(key, percentage) }

    let(:key) { :awesome_feature }
    let(:percentage) { 50 }

    it_behaves_like 'logging' do
      let(:expected_action) { :enable_percentage_of_actors }
      let(:expected_extra) { { "extra.percentage" => percentage.to_s } }
    end

    context 'when the flag is on' do
      before do
        described_class.enable(key)
      end

      it 'fails with InvalidOperation' do
        expect { subject }.to raise_error(described_class::InvalidOperation)
      end
    end
  end

  describe '.disable_percentage_of_actors' do
    subject { described_class.disable_percentage_of_actors(key) }

    let(:key) { :awesome_feature }

    it_behaves_like 'logging' do
      let(:expected_action) { :disable_percentage_of_actors }
      let(:expected_extra) { {} }
    end
  end

  describe '.remove' do
    subject { described_class.remove(key) }

    let(:key) { :awesome_feature }
    let(:actor) { create(:user) }

    before do
      described_class.enable(key)
    end

    it_behaves_like 'logging' do
      let(:expected_action) { :remove }
      let(:expected_extra) { {} }
    end

    context 'for a non-persisted feature' do
      it 'returns nil' do
        expect(described_class.remove(:non_persisted_feature_flag)).to be_nil
      end

      it 'returns true, and cleans up' do
        expect(subject).to be_truthy
        expect(described_class.persisted_names).not_to include(key)
      end
    end
  end

  describe '.log_feature_flag_states?' do
    let(:log_state_changes) { false }
    let(:milestone) { "0.0" }
    let(:flag_name) { :some_flag }
    let(:flag_type) { 'development' }

    before do
      described_class.enable(:feature_flag_state_logs)
      described_class.enable(:some_flag)

      allow(described_class).to receive(:log_feature_flag_states?).and_return(false)
      allow(described_class).to receive(:log_feature_flag_states?).with(:feature_flag_state_logs).and_call_original
      allow(described_class).to receive(:log_feature_flag_states?).with(:some_flag).and_call_original

      stub_feature_flag_definition(
        flag_name,
        type: flag_type,
        milestone: milestone,
        log_state_changes: log_state_changes
      )
    end

    subject { described_class.log_feature_flag_states?(flag_name) }

    context 'when flag is feature_flag_state_logs' do
      let(:milestone) { "14.6" }
      let(:flag_name) { :feature_flag_state_logs }
      let(:flag_type) { 'ops' }
      let(:log_state_changes) { true }

      it { is_expected.to be_falsey }
    end

    context 'when flag is old' do
      it { is_expected.to be_falsey }
    end

    context 'when flag is old while log_state_changes is not present ' do
      let(:log_state_changes) { nil }

      it { is_expected.to be_falsey }
    end

    context 'when flag is old but log_state_changes is true' do
      let(:log_state_changes) { true }

      it { is_expected.to be_truthy }
    end

    context 'when flag is new and not feature_flag_state_logs' do
      let(:milestone) { "14.6" }

      before do
        stub_version('14.5.123', 'deadbeef')
      end

      it { is_expected.to be_truthy }
    end

    context 'when milestone is nil' do
      let(:milestone) { nil }

      it { is_expected.to be_falsey }
    end
  end

  context 'caching with stale reads from the database', :use_clean_rails_redis_caching, :request_store, :aggregate_failures do
    let(:actor) { stub_feature_flag_gate('CustomActor:5') }
    let(:another_actor) { stub_feature_flag_gate('CustomActor:10') }

    # This is a bit unpleasant. For these tests we want to simulate stale reads
    # from the database (due to database load balancing). A simple way to do
    # that is to stub the response on the adapter Flipper uses for reading from
    # the database. However, there isn't a convenient API for this. We know that
    # the ActiveRecord adapter is always at the 'bottom' of the chain, so we can
    # find it that way.
    let(:active_record_adapter) do
      adapter = described_class.flipper

      loop do
        break adapter unless adapter.instance_variable_get(:@adapter)

        adapter = adapter.instance_variable_get(:@adapter)
      end
    end

    before do
      stub_feature_flag_definition(:enabled_feature_flag)
    end

    it 'gives the correct value when enabling for an additional actor' do
      described_class.enable(:enabled_feature_flag, actor)
      initial_gate_values = active_record_adapter.get(described_class.get(:enabled_feature_flag))

      # This should only be enabled for `actor`
      expect(described_class.enabled?(:enabled_feature_flag, actor)).to be(true)
      expect(described_class.enabled?(:enabled_feature_flag, another_actor)).to be(false)
      expect(described_class.enabled?(:enabled_feature_flag)).to be(false)

      # Enable for `another_actor` and simulate a stale read
      described_class.enable(:enabled_feature_flag, another_actor)
      allow(active_record_adapter).to receive(:get).once.and_return(initial_gate_values)

      # Should read from the cache and be enabled for both of these actors
      expect(described_class.enabled?(:enabled_feature_flag, actor)).to be(true)
      expect(described_class.enabled?(:enabled_feature_flag, another_actor)).to be(true)
      expect(described_class.enabled?(:enabled_feature_flag)).to be(false)
    end

    it 'gives the correct value when enabling for percentage of time' do
      described_class.enable_percentage_of_time(:enabled_feature_flag, 10)
      initial_gate_values = active_record_adapter.get(described_class.get(:enabled_feature_flag))

      # Test against `gate_values` directly as otherwise it would be non-determistic
      expect(described_class.get(:enabled_feature_flag).gate_values.percentage_of_time).to eq(10)

      # Enable 50% of time and simulate a stale read
      described_class.enable_percentage_of_time(:enabled_feature_flag, 50)
      allow(active_record_adapter).to receive(:get).once.and_return(initial_gate_values)

      # Should read from the cache and be enabled 50% of the time
      expect(described_class.get(:enabled_feature_flag).gate_values.percentage_of_time).to eq(50)
    end

    it 'gives the correct value when disabling the flag' do
      described_class.enable(:enabled_feature_flag, actor)
      described_class.enable(:enabled_feature_flag, another_actor)
      initial_gate_values = active_record_adapter.get(described_class.get(:enabled_feature_flag))

      # This be enabled for `actor` and `another_actor`
      expect(described_class.enabled?(:enabled_feature_flag, actor)).to be(true)
      expect(described_class.enabled?(:enabled_feature_flag, another_actor)).to be(true)
      expect(described_class.enabled?(:enabled_feature_flag)).to be(false)

      # Disable for `another_actor` and simulate a stale read
      described_class.disable(:enabled_feature_flag, another_actor)
      allow(active_record_adapter).to receive(:get).once.and_return(initial_gate_values)

      # Should read from the cache and be enabled only for `actor`
      expect(described_class.enabled?(:enabled_feature_flag, actor)).to be(true)
      expect(described_class.enabled?(:enabled_feature_flag, another_actor)).to be(false)
      expect(described_class.enabled?(:enabled_feature_flag)).to be(false)
    end

    it 'gives the correct value when deleting the flag' do
      described_class.enable(:enabled_feature_flag, actor)
      initial_gate_values = active_record_adapter.get(described_class.get(:enabled_feature_flag))

      # This should only be enabled for `actor`
      expect(described_class.enabled?(:enabled_feature_flag, actor)).to be(true)
      expect(described_class.enabled?(:enabled_feature_flag)).to be(false)

      # Remove and simulate a stale read
      described_class.remove(:enabled_feature_flag)
      allow(active_record_adapter).to receive(:get).once.and_return(initial_gate_values)

      # Should read from the cache and be disabled everywhere
      expect(described_class.enabled?(:enabled_feature_flag, actor)).to be(false)
      expect(described_class.enabled?(:enabled_feature_flag)).to be(false)
    end
  end

  describe Feature::Target do
    describe '#targets' do
      let(:project) { create(:project) }
      let(:group) { create(:group) }
      let(:user_name) { project.first_owner.username }

      subject do
        described_class.new(
          user: user_name,
          project: project.full_path,
          group: group.full_path,
          repository: project.repository.full_path
        )
      end

      it 'returns all found targets' do
        expect(subject.targets).to be_an(Array)
        expect(subject.targets).to eq([project.first_owner, project, group, project.repository])
      end

      context 'when repository target works with different types of repositories' do
        let_it_be(:group) { create(:group) }
        let_it_be(:project) { create(:project, :wiki_repo, group: group) }
        let_it_be(:project_in_user_namespace) { create(:project, namespace: create(:user).namespace) }
        let(:personal_snippet) { create(:personal_snippet) }
        let(:project_snippet) { create(:project_snippet, project: project) }

        let(:targets) do
          [
            project,
            project.wiki,
            project_in_user_namespace,
            personal_snippet,
            project_snippet
          ]
        end

        subject do
          described_class.new(
            repository: targets.map { |t| t.repository.full_path }.join(",")
          )
        end

        it 'returns all found targets' do
          expect(subject.targets).to be_an(Array)
          expect(subject.targets).to eq(targets.map(&:repository))
        end
      end
    end
  end

  def thing_enabled?
    described_class.enabled?(key, thing)
  end
end
