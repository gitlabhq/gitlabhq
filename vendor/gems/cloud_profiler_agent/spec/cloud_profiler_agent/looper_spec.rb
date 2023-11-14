# frozen_string_literal: true

require 'cloud_profiler_agent'

RSpec.describe CloudProfilerAgent::Looper, feature_category: :cloud_connector do
  # rubocop:disable RSpec/InstanceVariable
  before do
    @now = 0.0
  end

  subject do
    described_class.new(
      clock: -> { @now },
      sleeper: ->(secs) {
                 sleeps.push(secs)
                 @now += secs
               },
      rander: -> { rand },
      logger: Logger.new('/dev/null')
    )
  end

  let!(:sleeps) { [] }
  let(:rand) { 0.4 } # chosen by fair dice roll. guaranteed to be random.
  let(:min_time) { subject.min_iteration_sec }
  let(:max_time) { subject.max_iteration_sec }
  let(:backoff) { subject.backoff_factor }

  describe '#run' do
    it 'runs the block the specified number of times' do
      runs = []
      subject.run(3) do
        runs.push(true)
      end
      expect(runs.length).to eq(3)
    end

    it 'runs the block forever when max_iterations is not given' do
      # but we don't test this, because how do you test an infinite loop?
    end

    it 'will not run faster than min_iteration_sec' do
      subject.run(3) { nil }
      expect(sleeps).to eq([min_time, min_time])
    end

    context 'when the block takes some time' do
      it 'accounts for time taken by the block' do
        subject.run(3) { @now += 1 }
        expect(sleeps).to eq([min_time - 1, min_time - 1])
      end
    end

    context 'when the block takes longer than min_iteration_sec' do
      it 'does not sleep between iterations' do
        subject.run(3) { @now += 11 }
        expect(sleeps).to eq([])
      end
    end

    context 'when the block raises a StandardError' do
      it 'exponentially backs off' do
        subject.run(3) do
          @now += 1
          raise StandardError, 'bam'
        end

        factor = backoff + (rand / 2)
        expect(sleeps).to eq([(min_time * factor) - 1, (min_time * (factor**2)) - 1])
      end

      it 'respects max_iteration_sec' do
        subject.run(15) do
          @now += 1
          raise StandardError, 'bam'
        end

        expect(sleeps.last).to eq(max_time - 1)
      end
    end

    context 'when the block raises an Exception' do
      let(:exception_subject) do
        subject.run do
          raise Exception, 'bam'
        end
      end

      it 'logs the error and re-raises the exception' do
        expect_any_instance_of(Logger).to receive(:error).with(
          hash_including(
            gcp_ruby_status: "exception",
            error: "#<Exception: bam>"
          )
        )

        expect { exception_subject }.to raise_exception
      end
    end

    context 'when Google asks for backoff' do
      it 'slows down' do
        subject.run(2) do
          @now += 1
          raise backoff_exception('44m0s')
        end

        expect(sleeps.first).to eq(60 * 44)
      end
    end

    context 'when the block raises some other ClientError' do
      it 'goes to the maximum iteration time' do
        subject.run(2) do
          @now += 1
          raise ::Google::Cloud::InvalidArgumentError, 'you are a bad client'
        end

        expect(sleeps).to eq([max_time - 1])
      end
    end

    context 'when the block fails then works' do
      it 'backs off then returns to normal' do
        i = 0
        subject.run(4) do
          @now += 1
          i += 1
          raise 'whoops' if i == 1
        end

        factor = backoff + (rand / 2)
        expect(sleeps).to eq([(min_time * factor) - 1, min_time - 1, min_time - 1])
      end
    end
  end

  describe '#max_iteration_sec' do
    it 'is 1 hour by default' do
      expect(subject.max_iteration_sec).to eq(60 * 60)
    end
  end

  describe '#min_iteration_sec' do
    it 'is 10 seconds by default' do
      expect(subject.min_iteration_sec).to eq(10)
    end
  end

  describe '#backoff_factor' do
    it 'is 1.5 by default' do
      expect(subject.backoff_factor).to eq(1.5)
    end
  end

  def backoff_exception(duration)
    body = "{
      \"error\": {
        \"code\": 409,
        \"message\": \"generic::aborted: action throttled, backoff for #{duration}\",
        \"errors\": [
          {
            \"message\": \"generic::aborted: action throttled, backoff for #{duration}\",
            \"domain\": \"global\",
            \"reason\": \"aborted\"
          }
        ],
        \"status\": \"ABORTED\"
      }
    }
    "
    ::Google::Cloud::AlreadyExistsError.new(body) # AbortedError
  end

  # rubocop:enable RSpec/InstanceVariable
end
