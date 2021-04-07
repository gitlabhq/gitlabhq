# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::BatchedMigration, type: :model do
  it_behaves_like 'having unique enum values'

  describe 'associations' do
    it { is_expected.to have_many(:batched_jobs).with_foreign_key(:batched_background_migration_id) }

    describe '#last_job' do
      let!(:batched_migration) { create(:batched_background_migration) }
      let!(:batched_job1) { create(:batched_background_migration_job, batched_migration: batched_migration) }
      let!(:batched_job2) { create(:batched_background_migration_job, batched_migration: batched_migration) }

      it 'returns the most recent (in order of id) batched job' do
        expect(batched_migration.last_job).to eq(batched_job2)
      end
    end
  end

  describe '.queue_order' do
    let!(:migration1) { create(:batched_background_migration) }
    let!(:migration2) { create(:batched_background_migration) }
    let!(:migration3) { create(:batched_background_migration) }

    it 'returns batched migrations ordered by their id' do
      expect(described_class.queue_order.all).to eq([migration1, migration2, migration3])
    end
  end

  describe '.active_migration' do
    let!(:migration1) { create(:batched_background_migration, :finished) }
    let!(:migration2) { create(:batched_background_migration, :active) }
    let!(:migration3) { create(:batched_background_migration, :active) }

    it 'returns the first active migration according to queue order' do
      expect(described_class.active_migration).to eq(migration2)
    end
  end

  describe '#interval_elapsed?' do
    context 'when the migration has no last_job' do
      let(:batched_migration) { build(:batched_background_migration) }

      it 'returns true' do
        expect(batched_migration.interval_elapsed?).to eq(true)
      end
    end

    context 'when the migration has a last_job' do
      let(:interval) { 2.minutes }
      let(:batched_migration) { create(:batched_background_migration, interval: interval) }

      context 'when the last_job is less than an interval old' do
        it 'returns false' do
          freeze_time do
            create(:batched_background_migration_job,
              batched_migration: batched_migration,
              created_at: Time.current - 1.minute)

            expect(batched_migration.interval_elapsed?).to eq(false)
          end
        end
      end

      context 'when the last_job is exactly an interval old' do
        it 'returns true' do
          freeze_time do
            create(:batched_background_migration_job,
              batched_migration: batched_migration,
              created_at: Time.current - 2.minutes)

            expect(batched_migration.interval_elapsed?).to eq(true)
          end
        end
      end

      context 'when the last_job is more than an interval old' do
        it 'returns true' do
          freeze_time do
            create(:batched_background_migration_job,
              batched_migration: batched_migration,
              created_at: Time.current - 3.minutes)

            expect(batched_migration.interval_elapsed?).to eq(true)
          end
        end
      end

      context 'when an interval variance is given' do
        let(:variance) { 2.seconds }

        context 'when the last job is less than an interval with variance old' do
          it 'returns false' do
            freeze_time do
              create(:batched_background_migration_job,
                batched_migration: batched_migration,
                created_at: Time.current - 1.minute - 57.seconds)

              expect(batched_migration.interval_elapsed?(variance: variance)).to eq(false)
            end
          end
        end

        context 'when the last job is more than an interval with variance old' do
          it 'returns true' do
            freeze_time do
              create(:batched_background_migration_job,
                batched_migration: batched_migration,
                created_at: Time.current - 1.minute - 58.seconds)

              expect(batched_migration.interval_elapsed?(variance: variance)).to eq(true)
            end
          end
        end
      end
    end
  end

  describe '#create_batched_job!' do
    let(:batched_migration) { create(:batched_background_migration) }

    it 'creates a batched_job with the correct batch configuration' do
      batched_job = batched_migration.create_batched_job!(1, 5)

      expect(batched_job).to have_attributes(
        min_value: 1,
        max_value: 5,
        batch_size: batched_migration.batch_size,
        sub_batch_size: batched_migration.sub_batch_size)
    end
  end

  describe '#next_min_value' do
    let!(:batched_migration) { create(:batched_background_migration) }

    context 'when a previous job exists' do
      let!(:batched_job) { create(:batched_background_migration_job, batched_migration: batched_migration) }

      it 'returns the next value after the previous maximum' do
        expect(batched_migration.next_min_value).to eq(batched_job.max_value + 1)
      end
    end

    context 'when a previous job does not exist' do
      it 'returns the migration minimum value' do
        expect(batched_migration.next_min_value).to eq(batched_migration.min_value)
      end
    end
  end

  describe '#job_class' do
    let(:job_class) { Gitlab::BackgroundMigration::CopyColumnUsingBackgroundMigrationJob }
    let(:batched_migration) { build(:batched_background_migration) }

    it 'returns the class of the job for the migration' do
      expect(batched_migration.job_class).to eq(job_class)
    end
  end

  describe '#batch_class' do
    let(:batch_class) { Gitlab::BackgroundMigration::BatchingStrategies::PrimaryKeyBatchingStrategy}
    let(:batched_migration) { build(:batched_background_migration) }

    it 'returns the class of the batch strategy for the migration' do
      expect(batched_migration.batch_class).to eq(batch_class)
    end
  end

  shared_examples_for 'an attr_writer that demodulizes assigned class names' do |attribute_name|
    let(:batched_migration) { build(:batched_background_migration) }

    context 'when a module name exists' do
      it 'removes the module name' do
        batched_migration.public_send(:"#{attribute_name}=", '::Foo::Bar')

        expect(batched_migration[attribute_name]).to eq('Bar')
      end
    end

    context 'when a module name does not exist' do
      it 'does not change the given class name' do
        batched_migration.public_send(:"#{attribute_name}=", 'Bar')

        expect(batched_migration[attribute_name]).to eq('Bar')
      end
    end
  end

  describe '#job_class_name=' do
    it_behaves_like 'an attr_writer that demodulizes assigned class names', :job_class_name
  end

  describe '#batch_class_name=' do
    it_behaves_like 'an attr_writer that demodulizes assigned class names', :batch_class_name
  end
end
