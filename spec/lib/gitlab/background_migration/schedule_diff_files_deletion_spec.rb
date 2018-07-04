require 'spec_helper'

describe Gitlab::BackgroundMigration::ScheduleDiffFilesDeletion, :migration, schema: 20180619121030 do
  describe '#perform' do
    let(:merge_request_diffs) { table(:merge_request_diffs) }
    let(:diff_files) { table(:merge_request_diff_files) }
    let(:merge_requests) { table(:merge_requests) }
    let(:namespaces) { table(:namespaces) }
    let(:projects) { table(:projects) }

    def diff_file_params(extra_params = {})
      extra_params.merge(new_file: false,
                         renamed_file: false,
                         too_large: false,
                         deleted_file: false,
                         a_mode: 'foo',
                         b_mode: 'bar',
                         new_path: 'xpto',
                         old_path: 'kux',
                         diff: 'content')
    end

    def create_diffs(id:, files_number:, state: 'collected')
      merge_request_diffs.create!(id: id, merge_request_id: 1, state: state)
      files_number.times.to_a.each do |index|
        params = diff_file_params(merge_request_diff_id: id, relative_order: index)

        diff_files.create!(params)
      end
    end

    before do
      stub_const("#{described_class.name}::DELETION_BATCH", 10)

      namespaces.create!(id: 1, name: 'gitlab', path: 'gitlab')
      projects.create!(id: 1, namespace_id: 1, name: 'gitlab', path: 'gitlab')

      merge_requests.create!(id: 1, target_project_id: 1, source_project_id: 1, target_branch: 'feature', source_branch: 'master', state: 'merged')
    end

    it 'correctly schedules diff file deletion workers' do
      Sidekiq::Testing.fake! do
        Timecop.freeze do
          create_diffs(id: 1, files_number: 25)
          create_diffs(id: 2, files_number: 11)
          create_diffs(id: 3, files_number: 4, state: 'without_files')
          create_diffs(id: 4, files_number: 5, state: 'empty')
          create_diffs(id: 5, files_number: 9)

          worker = described_class.new

          expect(worker).to receive(:log_days_to_process_all_jobs).with(1.second + 2.5.minutes + 1.1.minutes + 0.9.minutes)

          worker.perform

          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(1.second, 1)
          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(1.second + 2.5.minutes, 2)
          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(1.second + 2.5.minutes + 1.1.minutes, 5)
          expect(BackgroundMigrationWorker.jobs.size).to eq(3)
        end
      end
    end
  end

  describe '#days_to_process_all_jobs' do
    it 'logs how many days it will take to run all jobs' do
      expect(Rails).to receive_message_chain(:logger, :info)
        .with("Gitlab::BackgroundMigration::DeleteDiffFiles will take 3 days to be processed")

      described_class.new.log_days_to_process_all_jobs(3.days.seconds)
    end
  end
end
