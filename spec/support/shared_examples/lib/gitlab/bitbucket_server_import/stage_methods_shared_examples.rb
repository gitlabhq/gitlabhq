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
end
