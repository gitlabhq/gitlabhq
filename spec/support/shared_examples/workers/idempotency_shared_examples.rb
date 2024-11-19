# frozen_string_literal: true

# This shared_example requires the following variables:
# - job_args (if not given, will fallback to call perform without arguments)
#
# Usage:
#
#   it_behaves_like 'an idempotent worker' do
#     it 'checks the side-effects for multiple calls' do
#       # it'll call the job's perform method 2 times
#       perform_idempotent_work
#
#       expect(model.state).to eq('state')
#     end
#   end
#
RSpec.shared_examples 'an idempotent worker' do
  let(:worker_exec_times) { IdempotentWorkerHelper::WORKER_EXEC_TIMES }

  # Avoid stubbing calls for a more accurate run.
  subject(:perform_idempotent_work) do
    if described_class.include?(::Gitlab::EventStore::Subscriber)
      event_worker
    else
      standard_worker
    end
  end

  it 'is labeled as idempotent' do
    expect(described_class).to be_idempotent
  end

  it 'performs multiple times sequentially without raising an exception' do
    expect { subject }.not_to raise_error
  end

  def event_worker
    consume_event(subscriber: described_class, event: event)
  end

  def standard_worker
    defined?(job_args) ? perform_multiple(job_args) : perform_multiple
  end
end
