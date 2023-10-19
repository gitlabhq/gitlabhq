# frozen_string_literal: true

RSpec.shared_examples Gitlab::GithubImport::StageMethods do
  describe '.sidekiq_retries_exhausted' do
    it 'tracks the exception and marks the import as failed' do
      expect(Gitlab::Import::ImportFailureService).to receive(:track)
        .with(
          project_id: 1,
          exception: StandardError,
          fail_import: true,
          error_source: anything
        )

      described_class.sidekiq_retries_exhausted_block.call({ 'args' => [1] }, StandardError.new)
    end
  end
end
