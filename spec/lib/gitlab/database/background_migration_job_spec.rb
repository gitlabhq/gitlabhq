# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigrationJob do
  it_behaves_like 'having unique enum values'

  it { is_expected.to be_a Gitlab::Database::SharedModel }

  describe '.for_migration_execution' do
    let!(:job1) { create(:background_migration_job) }
    let!(:job2) { create(:background_migration_job, arguments: ['hi', 2]) }
    let!(:job3) { create(:background_migration_job, class_name: 'OtherJob', arguments: ['hi', 2]) }

    it 'returns jobs matching class_name and arguments' do
      relation = described_class.for_migration_execution('TestJob', ['hi', 2])

      expect(relation.count).to eq(1)
      expect(relation.first).to have_attributes(class_name: 'TestJob', arguments: ['hi', 2])
    end

    it 'normalizes class names by removing leading ::' do
      relation = described_class.for_migration_execution('::TestJob', ['hi', 2])

      expect(relation.count).to eq(1)
      expect(relation.first).to have_attributes(class_name: 'TestJob', arguments: ['hi', 2])
    end
  end

  describe '.mark_all_as_succeeded' do
    let!(:job1) { create(:background_migration_job, arguments: [1, 100]) }
    let!(:job2) { create(:background_migration_job, arguments: [1, 100]) }
    let!(:job3) { create(:background_migration_job, arguments: [101, 200]) }
    let!(:job4) { create(:background_migration_job, class_name: 'OtherJob', arguments: [1, 100]) }

    it 'marks all matching jobs as succeeded' do
      expect { described_class.mark_all_as_succeeded('TestJob', [1, 100]) }
        .to change { described_class.succeeded.count }.from(0).to(2)

      expect(job1.reload).to be_succeeded
      expect(job2.reload).to be_succeeded
      expect(job3.reload).to be_pending
      expect(job4.reload).to be_pending
    end

    it 'normalizes class_names by removing leading ::' do
      expect { described_class.mark_all_as_succeeded('::TestJob', [1, 100]) }
        .to change { described_class.succeeded.count }.from(0).to(2)

      expect(job1.reload).to be_succeeded
      expect(job2.reload).to be_succeeded
      expect(job3.reload).to be_pending
      expect(job4.reload).to be_pending
    end

    it 'returns the number of jobs updated' do
      expect(described_class.succeeded.count).to eq(0)

      jobs_updated = described_class.mark_all_as_succeeded('::TestJob', [1, 100])

      expect(jobs_updated).to eq(2)
      expect(described_class.succeeded.count).to eq(2)
    end

    context 'when previous matching jobs have already succeeded' do
      let(:initial_time) { Time.now.round }
      let!(:job1) { create(:background_migration_job, :succeeded, created_at: initial_time, updated_at: initial_time) }

      it 'does not update non-pending jobs' do
        travel_to(initial_time + 1.day) do
          expect { described_class.mark_all_as_succeeded('TestJob', [1, 100]) }
            .to change { described_class.succeeded.count }.from(1).to(2)
        end

        expect(job1.reload.updated_at).to eq(initial_time)
        expect(job2.reload).to be_succeeded
        expect(job3.reload).to be_pending
        expect(job4.reload).to be_pending
      end
    end
  end

  describe '#class_name=' do
    context 'when the class_name is given without the leading ::' do
      it 'sets the class_name to the given value' do
        job = described_class.new(class_name: 'TestJob')

        expect(job.class_name).to eq('TestJob')
      end
    end

    context 'when the class_name is given with the leading ::' do
      it 'removes the leading :: when setting the class_name' do
        job = described_class.new(class_name: '::TestJob')

        expect(job.class_name).to eq('TestJob')
      end
    end

    context 'when the value is nil' do
      it 'sets the class_name to nil' do
        job = described_class.new(class_name: nil)

        expect(job.class_name).to be_nil
      end
    end

    context 'when the values is blank' do
      it 'sets the class_name to the given value' do
        job = described_class.new(class_name: '')

        expect(job.class_name).to eq('')
      end
    end
  end
end
