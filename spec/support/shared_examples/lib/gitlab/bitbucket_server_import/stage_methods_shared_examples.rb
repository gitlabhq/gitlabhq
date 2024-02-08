# frozen_string_literal: true

RSpec.shared_examples Gitlab::BitbucketServerImport::StageMethods do
  describe '.sidekiq_retries_exhausted' do
    let(:job) { { 'args' => [project.id] } }

    it 'tracks the import failure' do
      expect(Gitlab::Import::ImportFailureService)
        .to receive(:track).with(
          project_id: project.id,
          exception: StandardError.new,
          fail_import: true
        )

      described_class.sidekiq_retries_exhausted_block.call(job, StandardError.new)
    end
  end

  describe '#perform' do
    let(:worker) { described_class.new }

    it 'executes the import' do
      expect(worker).to receive(:import).with(project).once
      expect(Gitlab::BitbucketServerImport::Logger).to receive(:info).twice

      worker.perform(project.id)
    end

    it 'queues RefreshImportJidWorker' do
      allow(worker).to receive(:import)
      allow(worker).to receive(:jid).and_return('mock_jid')

      expect(Gitlab::Import::RefreshImportJidWorker)
        .to receive(:perform_in_the_future)
        .with(project.id, 'mock_jid')

      worker.perform(project.id)
    end
  end
end
