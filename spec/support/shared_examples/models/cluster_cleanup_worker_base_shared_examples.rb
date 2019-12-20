# frozen_string_literal: true

shared_examples 'cluster cleanup worker base specs' do
  it 'transitions to errored if sidekiq retries exhausted' do
    job = { 'args' => [cluster.id, 0], 'jid' => '123' }

    described_class.sidekiq_retries_exhausted_block.call(job)

    expect(cluster.reload.cleanup_status_name).to eq(:cleanup_errored)
  end
end
