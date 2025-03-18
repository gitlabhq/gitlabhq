# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::PlaceholderUserLimit, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:plan) { create(:default_plan) }

  before_all do
    create(:import_source_user, namespace: namespace)
    create(:import_source_user, :completed, namespace: namespace, placeholder_user: nil)
    create(:import_source_user)
  end

  describe '#exceeded?' do
    subject(:exceeded?) { described_class.new(namespace: namespace).exceeded? }

    context 'when plan has no limit' do
      it { is_expected.to eq(false) }
    end

    context 'when plan has a limit' do
      before do
        create(:plan_limits, plan: plan, import_placeholder_user_limit_tier_1: limit)
      end

      context 'when limit is 0 (unlimited)' do
        let(:limit) { 0 }

        it { is_expected.to eq(false) }
      end

      context 'when placeholder user count does not exceed the limit' do
        let(:limit) { 2 }

        it { is_expected.to eq(false) }

        it 'does not cache the result' do
          exceeded?

          instance = described_class.new(namespace: namespace)

          expect(instance.send(:cache).read(instance.send(:cache_key))).to be_nil
        end
      end

      context 'when placeholder user count exceeds the limit' do
        let(:limit) { 1 }

        it { is_expected.to eq(true) }

        it 'caches the result' do
          expect(Import::SourceUser).to receive(:namespace_placeholder_user_count).once.and_call_original

          2.times { expect(described_class.new(namespace: namespace).exceeded?).to eq(true) }

          instance = described_class.new(namespace: namespace)
          cache_key = instance.send(:cache_key)

          expect(instance.send(:cache).read(cache_key)).to eq('true')
        end

        it 'logs that the namespace has exceeded the limit' do
          expect(Import::Framework::Logger).to receive(:info).with(
            message: 'Placeholder user limit exceeded for namespace',
            limit: 1
          )

          exceeded?
        end
      end
    end
  end

  describe '#limit' do
    subject(:instance) { described_class.new(namespace: namespace) }

    context 'when plan has a limit' do
      let(:limit) { 2 }

      before do
        create(:plan_limits, plan: plan, import_placeholder_user_limit_tier_1: limit)
      end

      it { expect(instance.limit).to eq(limit) }

      it 'caches the result' do
        allow_next_instance_of(PlanLimits) do |plan_limit|
          expect(plan_limit).to receive(:limit_for).once.and_call_original
        end

        2.times { expect(described_class.new(namespace: namespace).limit).to eq(limit) }
      end
    end

    context 'when plan has no limit (unlimited)' do
      it { expect(instance.limit).to eq(0) }

      it 'caches the result' do
        allow_next_instance_of(PlanLimits) do |plan_limit|
          expect(plan_limit).to receive(:limit_for).once.and_call_original
        end

        2.times { expect(described_class.new(namespace: namespace).limit).to eq(0) }
      end
    end
  end

  describe '#count' do
    let(:limit) { 2 }

    subject(:instance) { described_class.new(namespace: namespace) }

    before do
      allow(instance).to receive(:limit).and_return(limit)
    end

    it 'returns the count' do
      expect(Import::SourceUser).to receive(:namespace_placeholder_user_count).with(namespace, limit: limit)
                                                                              .and_call_original

      expect(instance.count).to eq(1)
    end
  end
end
