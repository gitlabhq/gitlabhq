# frozen_string_literal: true

require 'spec_helper'

describe Feature do
  before do
    # We mock all calls to .enabled? to return true in order to force all
    # specs to run the feature flag gated behavior, but here we need a clean
    # behavior from the class
    allow(described_class).to receive(:enabled?).and_call_original
  end

  describe '.get' do
    let(:feature) { double(:feature) }
    let(:key) { 'my_feature' }

    it 'returns the Flipper feature' do
      expect_any_instance_of(Flipper::DSL).to receive(:feature).with(key)
        .and_return(feature)

      expect(described_class.get(key)).to be(feature)
    end
  end

  describe '.persisted_names' do
    it 'returns the names of the persisted features' do
      Feature::FlipperFeature.create!(key: 'foo')

      expect(described_class.persisted_names).to eq(%w[foo])
    end

    it 'returns an empty Array when no features are presisted' do
      expect(described_class.persisted_names).to be_empty
    end

    it 'caches the feature names when request store is active',
       :request_store, :use_clean_rails_memory_store_caching do
      Feature::FlipperFeature.create!(key: 'foo')

      expect(Feature::FlipperFeature)
        .to receive(:feature_names)
        .once
        .and_call_original

      expect(Gitlab::ThreadMemoryCache.cache_backend)
        .to receive(:fetch)
        .once
        .with('flipper:persisted_names', expires_in: 1.minute)
        .and_call_original

      2.times do
        expect(described_class.persisted_names).to eq(%w[foo])
      end
    end
  end

  describe '.persisted?' do
    context 'when the feature is persisted' do
      it 'returns true when feature name is a string' do
        Feature::FlipperFeature.create!(key: 'foo')

        feature = double(:feature, name: 'foo')

        expect(described_class.persisted?(feature)).to eq(true)
      end

      it 'returns true when feature name is a symbol' do
        Feature::FlipperFeature.create!(key: 'foo')

        feature = double(:feature, name: :foo)

        expect(described_class.persisted?(feature)).to eq(true)
      end
    end

    context 'when the feature is not persisted' do
      it 'returns false when feature name is a string' do
        feature = double(:feature, name: 'foo')

        expect(described_class.persisted?(feature)).to eq(false)
      end

      it 'returns false when feature name is a symbol' do
        feature = double(:feature, name: :bar)

        expect(described_class.persisted?(feature)).to eq(false)
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
    before do
      described_class.instance_variable_set(:@flipper, nil)
    end

    context 'when request store is inactive' do
      it 'memoizes the Flipper instance' do
        expect(Flipper).to receive(:new).once.and_call_original

        2.times do
          described_class.flipper
        end
      end
    end

    context 'when request store is active', :request_store do
      it 'memoizes the Flipper instance' do
        expect(Flipper).to receive(:new).once.and_call_original

        described_class.flipper
        described_class.instance_variable_set(:@flipper, nil)
        described_class.flipper
      end
    end
  end

  describe '.enabled?' do
    it 'returns false for undefined feature' do
      expect(described_class.enabled?(:some_random_feature_flag)).to be_falsey
    end

    it 'returns true for undefined feature with default_enabled' do
      expect(described_class.enabled?(:some_random_feature_flag, default_enabled: true)).to be_truthy
    end

    it 'returns false for existing disabled feature in the database' do
      described_class.disable(:disabled_feature_flag)

      expect(described_class.enabled?(:disabled_feature_flag)).to be_falsey
    end

    it 'returns true for existing enabled feature in the database' do
      described_class.enable(:enabled_feature_flag)

      expect(described_class.enabled?(:enabled_feature_flag)).to be_truthy
    end

    it { expect(described_class.l1_cache_backend).to eq(Gitlab::ThreadMemoryCache.cache_backend) }
    it { expect(described_class.l2_cache_backend).to eq(Rails.cache) }

    it 'caches the status in L1 and L2 caches',
       :request_store, :use_clean_rails_memory_store_caching do
      described_class.enable(:enabled_feature_flag)
      flipper_key = "flipper/v1/feature/enabled_feature_flag"

      expect(described_class.l2_cache_backend)
        .to receive(:fetch)
        .once
        .with(flipper_key, expires_in: 1.hour)
        .and_call_original

      expect(described_class.l1_cache_backend)
        .to receive(:fetch)
        .once
        .with(flipper_key, expires_in: 1.minute)
        .and_call_original

      2.times do
        expect(described_class.enabled?(:enabled_feature_flag)).to be_truthy
      end
    end

    context 'cached feature flag', :request_store do
      let(:flag) { :some_feature_flag }

      before do
        stub_feature_flags(Gitlab::Marginalia::MARGINALIA_FEATURE_FLAG => false)
        described_class.flipper.memoize = false
        described_class.enabled?(flag)
      end

      it 'caches the status in L1 cache for the first minute' do
        expect do
          expect(described_class.l1_cache_backend).to receive(:fetch).once.and_call_original
          expect(described_class.l2_cache_backend).not_to receive(:fetch)
          expect(described_class.enabled?(flag)).to be_truthy
        end.not_to exceed_query_limit(0)
      end

      it 'caches the status in L2 cache after 2 minutes' do
        Timecop.travel 2.minutes do
          expect do
            expect(described_class.l1_cache_backend).to receive(:fetch).once.and_call_original
            expect(described_class.l2_cache_backend).to receive(:fetch).once.and_call_original
            expect(described_class.enabled?(flag)).to be_truthy
          end.not_to exceed_query_limit(0)
        end
      end

      it 'fetches the status after an hour' do
        Timecop.travel 61.minutes do
          expect do
            expect(described_class.l1_cache_backend).to receive(:fetch).once.and_call_original
            expect(described_class.l2_cache_backend).to receive(:fetch).once.and_call_original
            expect(described_class.enabled?(flag)).to be_truthy
          end.not_to exceed_query_limit(1)
        end
      end
    end

    context 'with an individual actor' do
      CustomActor = Struct.new(:flipper_id)

      let(:actor) { CustomActor.new(flipper_id: 'CustomActor:5') }
      let(:another_actor) { CustomActor.new(flipper_id: 'CustomActor:10') }

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
  end

  describe '.disable?' do
    it 'returns true for undefined feature' do
      expect(described_class.disabled?(:some_random_feature_flag)).to be_truthy
    end

    it 'returns false for undefined feature with default_enabled' do
      expect(described_class.disabled?(:some_random_feature_flag, default_enabled: true)).to be_falsey
    end

    it 'returns true for existing disabled feature in the database' do
      described_class.disable(:disabled_feature_flag)

      expect(described_class.disabled?(:disabled_feature_flag)).to be_truthy
    end

    it 'returns false for existing enabled feature in the database' do
      described_class.enable(:enabled_feature_flag)

      expect(described_class.disabled?(:enabled_feature_flag)).to be_falsey
    end
  end

  describe '.remove' do
    context 'for a non-persisted feature' do
      it 'returns nil' do
        expect(described_class.remove(:non_persisted_feature_flag)).to be_nil
      end
    end

    context 'for a persisted feature' do
      it 'returns true' do
        described_class.enable(:persisted_feature_flag)

        expect(described_class.remove(:persisted_feature_flag)).to be_truthy
      end
    end
  end

  describe Feature::Target do
    describe '#targets' do
      let(:project) { create(:project) }
      let(:group) { create(:group) }
      let(:user_name) { project.owner.username }

      subject { described_class.new(user: user_name, project: project.full_path, group: group.full_path) }

      it 'returns all found targets' do
        expect(subject.targets).to be_an(Array)
        expect(subject.targets).to eq([project.owner, project, group])
      end
    end
  end
end
