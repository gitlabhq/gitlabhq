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
        expect(service.fetch('main') { true }).to be(true)
        expect(service.fetch('not-found') { false }).to be(false)

        # Uses cached values
        expect(service.fetch('main') { false }).to be(true)
        expect(service.fetch('not-found') { true }).to be(false)
      end

      it 'sets expiry on the key' do
        stub_const("#{described_class.name}::CACHE_EXPIRE_IN", immediate_expiration)

        expect(service.fetch('main') { true }).to be(true)
        expect(service.fetch('not-found') { false }).to be(false)

        expect(service.fetch('main') { false }).to be(false)
        expect(service.fetch('not-found') { true }).to be(true)
      end

      it 'does not set an expiry on the key after the hash is already created' do
        expect(service.fetch('main') { true }).to be(true)

        stub_const("#{described_class.name}::CACHE_EXPIRE_IN", immediate_expiration)

        expect(service.fetch('not-found') { false }).to be(false)

        expect(service.fetch('main') { false }).to be(true)
        expect(service.fetch('not-found') { true }).to be(false)
      end

      context 'when CACHE_LIMIT is exceeded' do
        before do
          stub_const("#{described_class.name}::CACHE_LIMIT", 2)
        end

        it 'recreates cache' do
          expect(service.fetch('main') { true }).to be(true)
          expect(service.fetch('not-found') { false }).to be(false)

          # Uses cached values
          expect(service.fetch('main') { false }).to be(true)
          expect(service.fetch('not-found') { true }).to be(false)

          # Overflow
          expect(service.fetch('new-branch') { true }).to be(true)

          # Refreshes values
          expect(service.fetch('main') { false }).to be(false)
          expect(service.fetch('not-found') { true }).to be(true)
        end
      end

      context 'when dry_run is on' do
        it 'does not use cached value' do
          expect(service.fetch('main', dry_run: true) { true }).to be(true)
          expect(service.fetch('main', dry_run: true) { false }).to be(false)
        end

        context 'when cache mismatch' do
          it 'logs an error' do
            expect(service.fetch('main', dry_run: true) { true }).to be(true)

            expect(Gitlab::AppLogger).to receive(:error).with(
              {
                'class' => described_class.name,
                'message' => /Cache mismatch/,
                'record_class' => entity.class.name,
                'record_id' => entity.id,
                'record_path' => entity.full_path
              }
            )

            expect(service.fetch('main', dry_run: true) { false }).to be(false)
          end
        end

        context 'when cache matches' do
          it 'does not log an error' do
            expect(service.fetch('main', dry_run: true) { true }).to be(true)

            expect(Gitlab::AppLogger).not_to receive(:error)

            expect(service.fetch('main', dry_run: true) { true }).to be(true)
          end
        end
      end
    end

    describe '#refresh' do
      let(:project_service) { described_class.new(project, user) }

      it 'clears cached values', time_travel_to: 1.minute.from_now do
        expect(service.fetch('main') { true }).to be(true)
        expect(service.fetch('not-found') { false }).to be(false)

        if entity.is_a?(Group)
          expect(project_service.fetch('main') { true }).to be(true)
          expect(project_service.fetch('not-found') { false }).to be(false)
          # When refreshing a group we also touch each project within the
          # group.
          expect { service.refresh }.to change { project.reload.updated_at }.to(Time.current)
        else
          # We already touch the project when updating a project's protected
          # branches so refresh shouldn't affect the project
          expect { service.refresh }.not_to change { project.reload.updated_at }
        end

        # Recreates cache
        expect(service.fetch('main') { false }).to be(false)
        expect(service.fetch('not-found') { true }).to be(true)

        # Refreshes caches for each project in the group
        if entity.is_a?(Group)
          expect(project_service.fetch('main') { false }).to be(false)
          expect(project_service.fetch('not-found') { true }).to be(true)
        end
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
    let(:project) { entity }
    let(:user) { entity.first_owner }

    it_behaves_like 'execute with entity'
  end

  context 'with entity group' do
    let_it_be_with_reload(:project) { create(:project, :in_group) }
    let_it_be_with_reload(:entity) { project.group }
    let_it_be_with_reload(:user) { create(:user) }

    before_all do
      entity.add_owner(user)
    end

    it_behaves_like 'execute with entity'
  end
end
# rubocop:enable Style/RedundantFetchBlock
