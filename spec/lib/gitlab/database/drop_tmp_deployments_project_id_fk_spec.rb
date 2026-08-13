# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::DropTmpDeploymentsProjectIdFk, feature_category: :database do
  include ExclusiveLeaseHelpers

  let(:drop_constraint_query) { /ALTER TABLE deployments DROP CONSTRAINT fk_b9a3851b82_tmp/ }

  before do
    stub_feature_flags(disallow_database_ddl_feature_flags: false)
    stub_feature_flags(drop_tmp_deployments_project_id_fk: true)
  end

  describe '#execute' do
    context 'when the foreign key exists' do
      before do
        stub_foreign_key_exists(true)
        stub_wraparound_vacuum([])
      end

      it 'drops the foreign key' do
        recorder = ActiveRecord::QueryRecorder.new { described_class.new.execute }

        expect(recorder.log).to include(drop_constraint_query)
      end

      it 'locks projects before deployments to match the migration lock order' do
        recorder = ActiveRecord::QueryRecorder.new { described_class.new.execute }

        expect(recorder.log).to include(/LOCK TABLE projects, deployments IN ACCESS EXCLUSIVE MODE/)
      end

      context 'when the ops feature flag is disabled' do
        before do
          stub_feature_flags(drop_tmp_deployments_project_id_fk: false)
        end

        it 'does not drop the foreign key' do
          recorder = ActiveRecord::QueryRecorder.new { described_class.new.execute }

          expect(recorder.log).not_to include(drop_constraint_query)
        end
      end

      context 'when a wraparound prevention vacuum is running' do
        before do
          stub_wraparound_vacuum([instance_double(Gitlab::Database::PostgresAutovacuumActivity)])
        end

        it 'does not drop the foreign key' do
          recorder = ActiveRecord::QueryRecorder.new { described_class.new.execute }

          expect(recorder.log).not_to include(drop_constraint_query)
        end
      end

      context 'when the lease is already taken' do
        before do
          stub_exclusive_lease_taken(described_class.new.lease_key)
        end

        it 'does not drop the foreign key' do
          recorder = ActiveRecord::QueryRecorder.new { described_class.new.execute }

          expect(recorder.log).not_to include(drop_constraint_query)
        end
      end

      context 'when dropping the foreign key raises' do
        before do
          allow_next_instance_of(Gitlab::Database::WithLockRetries) do |instance|
            allow(instance).to receive(:run).and_raise(
              Gitlab::Database::WithLockRetries::AttemptsExhaustedError, 'exhausted'
            )
          end
        end

        it 'logs the failure instead of propagating it' do
          expect(Gitlab::AppLogger).to receive(:info).with(
            hash_including(Labkit::Fields::CLASS_NAME => described_class.to_s)
          )

          expect { described_class.new.execute }.not_to raise_error
        end
      end
    end

    context 'when the foreign key does not exist' do
      before do
        stub_foreign_key_exists(false)
        stub_wraparound_vacuum([])
      end

      it 'does not drop the foreign key' do
        recorder = ActiveRecord::QueryRecorder.new { described_class.new.execute }

        expect(recorder.log).not_to include(drop_constraint_query)
      end
    end
  end

  def stub_foreign_key_exists(exists)
    scope = class_double(Gitlab::Database::PostgresForeignKey, exists?: exists)

    allow(Gitlab::Database::PostgresForeignKey).to receive(:by_constrained_table_name).and_return(scope)
    allow(scope).to receive_messages(by_referenced_table_name: scope, by_name: scope)
  end

  def stub_wraparound_vacuum(activities)
    scope = class_double(Gitlab::Database::PostgresAutovacuumActivity, for_tables: activities)

    allow(Gitlab::Database::PostgresAutovacuumActivity).to receive(:wraparound_prevention).and_return(scope)
  end
end
