# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe 'gitlab:cleanup:untracked_object_storage_files rake task', :silence_stdout, feature_category: :geo_replication do
  subject(:rake_task) { run_rake_task('gitlab:cleanup:untracked_object_storage_files') }

  let(:logger) { Logger.new(nil) }
  let(:artifacts_cleaner) { instance_double(Gitlab::Cleanup::RemoteArtifacts) }
  let(:uploads_cleaner) { instance_double(Gitlab::Cleanup::RemoteUploads) }

  before do
    Rake.application.rake_require 'tasks/gitlab/cleanup'
    allow(main_object).to receive(:logger).and_return(logger)
  end

  it 'runs all available cleaners when no buckets specified' do
    available_buckets = Gitlab::Cleanup::ObjectStorageCleanerMapping.buckets

    available_buckets.each do |bucket|
      cleaner_class = Gitlab::Cleanup::ObjectStorageCleanerMapping.cleaner_class_for(bucket)
      expect_next_instance_of(cleaner_class) do |cleaner|
        expect(cleaner).to receive(:run!).with(dry_run: true, delete: false)
      end
    end

    rake_task
  end

  context 'with specific buckets' do
    before do
      stub_env('BUCKETS', 'artifacts')
    end

    it 'runs only the specified cleaners' do
      expect(Gitlab::Cleanup::RemoteArtifacts).to receive(:new).with(logger: logger).and_return(artifacts_cleaner)

      expect(artifacts_cleaner).to receive(:run!).with(dry_run: true, delete: false)

      # Other cleaners should not be called
      expect(Gitlab::Cleanup::RemoteUploads).not_to receive(:new)

      rake_task
    end
  end

  context 'with invalid buckets' do
    before do
      stub_env('BUCKETS', 'artifacts,invalid_bucket')
    end

    it 'warns about invalid buckets and continues with valid ones' do
      expect(logger).to receive(:warn).with(a_string_matching(/Invalid bucket types: invalid_bucket/))

      expect(Gitlab::Cleanup::RemoteArtifacts).to receive(:new).with(logger: logger).and_return(artifacts_cleaner)
      expect(artifacts_cleaner).to receive(:run!).with(dry_run: true, delete: false)

      rake_task
    end
  end

  context 'with DRY_RUN set to false' do
    before do
      stub_env('DRY_RUN', 'false')
      stub_env('BUCKETS', 'artifacts')
    end

    it 'passes dry_run=false to the cleaner' do
      expect(Gitlab::Cleanup::RemoteArtifacts).to receive(:new).with(logger: logger).and_return(artifacts_cleaner)
      expect(artifacts_cleaner).to receive(:run!).with(dry_run: false, delete: false)

      rake_task
    end
  end

  context 'with DELETE set to true' do
    before do
      stub_env('DELETE', 'true')
      stub_env('BUCKETS', 'artifacts')
    end

    it 'passes delete=true to the cleaner' do
      expect(Gitlab::Cleanup::RemoteArtifacts).to receive(:new).with(logger: logger).and_return(artifacts_cleaner)
      expect(artifacts_cleaner).to receive(:run!).with(dry_run: true, delete: true)

      rake_task
    end
  end

  context 'when a cleaner raises an error' do
    before do
      stub_env('BUCKETS', 'artifacts,uploads')
    end

    it 'logs the error and continues with other buckets' do
      expect(Gitlab::Cleanup::RemoteArtifacts).to receive(:new).with(logger: logger).and_return(artifacts_cleaner)
      expect(artifacts_cleaner).to receive(:run!).and_raise(StandardError.new("Test error"))

      expect(Gitlab::Cleanup::RemoteUploads).to receive(:new).with(logger: logger).and_return(uploads_cleaner)
      expect(uploads_cleaner).to receive(:run!).with(dry_run: true, delete: false)

      allow(logger).to receive(:error)
      expect(logger).to receive(:error).with(a_string_matching(/Error processing bucket type artifacts: Test error/))

      rake_task
    end
  end

  context 'when DRY_RUN is true' do
    before do
      stub_env('DRY_RUN', 'true')
      stub_env('BUCKETS', 'artifacts')
    end

    it 'logs a message about this being a dry run' do
      expect(Gitlab::Cleanup::RemoteArtifacts).to receive(:new).with(logger: logger).and_return(artifacts_cleaner)
      expect(artifacts_cleaner).to receive(:run!).with(dry_run: true, delete: false)

      allow(logger).to receive(:info)
      expect(logger).to receive(:info).with(a_string_matching(/This was a dry run/))

      rake_task
    end
  end
end
