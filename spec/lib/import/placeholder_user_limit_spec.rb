# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::PlaceholderUserLimit, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:plan) { create(:default_plan) }

  describe '#exceeded?' do
    subject(:exceeded?) { described_class.new(namespace: namespace).exceeded? }

    before_all do
      create(:import_source_user, namespace: namespace)
    end

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
end
