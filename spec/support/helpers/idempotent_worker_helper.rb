# frozen_string_literal: true

module IdempotentWorkerHelper
  WORKER_EXEC_TIMES = 2

  def perform_multiple(args = [], worker: described_class.new, exec_times: WORKER_EXEC_TIMES)
    Sidekiq::Testing.inline! do
      job_args = args.nil? ? [nil] : Array.wrap(args)

      expect(worker).to receive(:perform).exactly(exec_times).and_call_original

      exec_times.times { worker.perform(*job_args) }
    end
  end
end
