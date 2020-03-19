# frozen_string_literal: true

# This shared_example requires the following variables:
# - job_args (if not given, will fallback to call perform without arguments)
#
# Usage:
#
#   include_examples 'an idempotent worker' do
#     it 'checks the side-effects for multiple calls' do
#       # it'll call the job's perform method 3 times
#       # by default.
#       subject
#
#       expect(model.state).to eq('state')
#     end
#   end
#
RSpec.shared_examples 'an idempotent worker' do
  let(:worker_exec_times) { IdempotentWorkerHelper::WORKER_EXEC_TIMES }

  # Avoid stubbing calls for a more accurate run.
  subject do
    defined?(job_args) ? perform_multiple(job_args) : perform_multiple
  end

  it 'is labeled as idempotent' do
    expect(described_class).to be_idempotent
  end

  it 'performs multiple times sequentially without raising an exception' do
    expect { subject }.not_to raise_error
  end
end
