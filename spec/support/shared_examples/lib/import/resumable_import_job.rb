# frozen_string_literal: true

RSpec.shared_examples Import::ResumableImportJob do
  it 'sets a higher limit for retries after interruption' do
    expect(described_class.sidekiq_options['max_retries_after_interruption'])
      .to eq(Import::ResumableImportJob::MAX_RETRIES_AFTER_INTERRUPTION)
  end
end
