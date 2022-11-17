# frozen_string_literal: true

RSpec.shared_context 'when handling retried jobs' do |url|
  let(:set_name) { 'retry' }
  # Account for Sidekiq retry jitter
  # https://github.com/mperham/sidekiq/blob/3575ccb44c688dd08bfbfd937696260b12c622fb/lib/sidekiq/job_retry.rb#L217
  let(:schedule_jitter) { 10 }

  # Try to mimic as closely as possible what Sidekiq will actually
  # do to retry a job.
  def retry_in(klass, time, args = 0)
    message = Gitlab::Json.generate(
      'class' => klass.name,
      'args' => [args],
      'retry' => true
    )

    allow(klass).to receive(:sidekiq_retry_in_block).and_return(proc { time.to_i })

    begin
      Sidekiq::JobRetry.new(Sidekiq).local(klass, message, klass.queue) { raise 'boom' }
    rescue Sidekiq::JobRetry::Skip
      # Sidekiq scheduled the retry
    end
  end
end
