# frozen_string_literal: true
# rubocop:disable Style/RedundantFetchBlock
#
require 'spec_helper'

RSpec.describe ProtectedBranches::CacheService, :clean_gitlab_redis_cache, feature_category: :compliance_management do
  shared_examples 'execute with entity' do
    subject(:service) { described_class.new(entity, user) }

    let(:immediate_expiration) { 0 }

    describe '#fetch' do
      it 'caches the value' do
        expect(service.fetch('main') { true }).to eq(true)
        expect(service.fetch('not-found') { false }).to eq(false)

        # Uses cached values
        expect(service.fetch('main') { false }).to eq(true)
        expect(service.fetch('not-found') { true }).to eq(false)
      end

      it 'sets expiry on the key' do
        stub_const("#{described_class.name}::CACHE_EXPIRE_IN", immediate_expiration)

        expect(service.fetch('main') { true }).to eq(true)
        expect(service.fetch('not-found') { false }).to eq(false)

        expect(service.fetch('main') { false }).to eq(false)
        expect(service.fetch('not-found') { true }).to eq(true)
      end

      it 'does not set an expiry on the key after the hash is already created' do
        expect(service.fetch('main') { true }).to eq(true)

        stub_const("#{described_class.name}::CACHE_EXPIRE_IN", immediate_expiration)

        expect(service.fetch('not-found') { false }).to eq(false)

        expect(service.fetch('main') { false }).to eq(true)
        expect(service.fetch('not-found') { true }).to eq(false)
      end

      context 'when CACHE_LIMIT is exceeded' do
        before do
          stub_const("#{described_class.name}::CACHE_LIMIT", 2)
        end

        it 'recreates cache' do
          expect(service.fetch('main') { true }).to eq(true)
          expect(service.fetch('not-found') { false }).to eq(false)

          # Uses cached values
          expect(service.fetch('main') { false }).to eq(true)
          expect(service.fetch('not-found') { true }).to eq(false)

          # Overflow
          expect(service.fetch('new-branch') { true }).to eq(true)

          # Refreshes values
          expect(service.fetch('main') { false }).to eq(false)
          expect(service.fetch('not-found') { true }).to eq(true)
        end
      end

      context 'when dry_run is on' do
        it 'does not use cached value' do
          expect(service.fetch('main', dry_run: true) { true }).to eq(true)
          expect(service.fetch('main', dry_run: true) { false }).to eq(false)
        end

        context 'when cache mismatch' do
          it 'logs an error' do
            expect(service.fetch('main', dry_run: true) { true }).to eq(true)

            expect(Gitlab::AppLogger).to receive(:error).with(
              {
                'class' => described_class.name,
                'message' => /Cache mismatch/,
                'record_class' => entity.class.name,
                'record_id' => entity.id,
                'record_path' => entity.full_path
              }
            )

            expect(service.fetch('main', dry_run: true) { false }).to eq(false)
          end
        end

        context 'when cache matches' do
          it 'does not log an error' do
            expect(service.fetch('main', dry_run: true) { true }).to eq(true)

            expect(Gitlab::AppLogger).not_to receive(:error)

            expect(service.fetch('main', dry_run: true) { true }).to eq(true)
          end
        end
      end
    end

    describe '#refresh' do
      it 'clears cached values' do
        expect(service.fetch('main') { true }).to eq(true)
        expect(service.fetch('not-found') { false }).to eq(false)

        service.refresh

        # Recreates cache
        expect(service.fetch('main') { false }).to eq(false)
        expect(service.fetch('not-found') { true }).to eq(true)
      end
    end

    describe 'metrics' do
      it 'records hit ratio metrics' do
        expect_next_instance_of(Gitlab::Cache::Metrics) do |metrics|
          expect(metrics).to receive(:increment_cache_miss).once
          expect(metrics).to receive(:increment_cache_hit).exactly(4).times
        end

        5.times { service.fetch('main') { true } }
      end
    end
  end

  context 'with entity project' do
    let_it_be_with_reload(:entity) { create(:project) }
    let(:user) { entity.first_owner }

    it_behaves_like 'execute with entity'
  end

  context 'with entity group' do
    let_it_be_with_reload(:entity) { create(:group) }
    let_it_be_with_reload(:user) { create(:user) }

    before do
      entity.add_owner(user)
    end

    context 'when feature flag enabled' do
      it_behaves_like 'execute with entity'
    end

    context 'when feature flag disabled' do
      before do
        stub_feature_flags(group_protected_branches: false)
        stub_feature_flags(allow_protected_branches_for_group: false)
      end

      it_behaves_like 'execute with entity'
    end
  end
end
# rubocop:enable Style/RedundantFetchBlock
