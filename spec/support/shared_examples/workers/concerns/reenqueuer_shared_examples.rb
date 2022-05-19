# frozen_string_literal: true

# Expects `subject` to be a job/worker instance and
# `job_args` to be arguments to #perform if it takes arguments
RSpec.shared_examples 'reenqueuer' do
  before do
    allow(subject).to receive(:sleep) # faster tests
  end

  let(:subject_perform) { defined?(job_args) ? subject.perform(job_args) : subject.perform }

  it 'implements lease_timeout' do
    expect(subject.lease_timeout).to be_a(ActiveSupport::Duration)
  end

  it 'uses the :none deduplication strategy' do
    expect(subject.class.get_deduplicate_strategy).to eq(:none)
  end

  describe '#perform' do
    it 'tries to obtain a lease' do
      lease_key = if subject.respond_to?(:set_custom_lease_key)
                    subject.set_custom_lease_key(*job_args)
                  else
                    subject.lease_key
                  end

      expect_to_obtain_exclusive_lease(lease_key)

      subject_perform
    end
  end
end

# Expects `subject` to be a job/worker instance and
# `job_args` to be arguments to #perform if it takes arguments
RSpec.shared_examples '#perform is rate limited to 1 call per' do |minimum_duration|
  before do
    freeze_time

    time_travel_during_perform(actual_duration)
  end

  let(:subject_perform) { defined?(job_args) ? subject.perform(job_args) : subject.perform }

  context 'when the work finishes in 0 seconds' do
    let(:actual_duration) { 0 }

    it 'sleeps exactly the minimum duration' do
      expect(subject).to receive(:sleep).with(a_value_within(0.01).of(minimum_duration))

      subject_perform
    end
  end

  context 'when the work finishes in 10% of minimum duration' do
    let(:actual_duration) { 0.1 * minimum_duration }

    it 'sleeps 90% of minimum duration' do
      expect(subject).to receive(:sleep).with(a_value_within(1).of(0.9 * minimum_duration))

      subject_perform
    end
  end

  context 'when the work finishes in 90% of minimum duration' do
    let(:actual_duration) { 0.9 * minimum_duration }

    it 'sleeps 10% of minimum duration' do
      expect(subject).to receive(:sleep).with(a_value_within(1).of(0.1 * minimum_duration))

      subject_perform
    end
  end

  context 'when the work finishes exactly at minimum duration' do
    let(:actual_duration) { minimum_duration }

    it 'does not sleep' do
      expect(subject).not_to receive(:sleep)

      subject_perform
    end
  end

  context 'when the work takes 10% longer than minimum duration' do
    let(:actual_duration) { 1.1 * minimum_duration }

    it 'does not sleep' do
      expect(subject).not_to receive(:sleep)

      subject_perform
    end
  end

  context 'when the work takes twice as long as minimum duration' do
    let(:actual_duration) { 2 * minimum_duration }

    it 'does not sleep' do
      expect(subject).not_to receive(:sleep)

      subject_perform
    end
  end

  def time_travel_during_perform(actual_duration)
    # Save the original implementation of ensure_minimum_duration
    original_ensure_minimum_duration = subject.method(:ensure_minimum_duration)

    allow(subject).to receive(:ensure_minimum_duration) do |minimum_duration, &block|
      original_ensure_minimum_duration.call(minimum_duration) do
        # Time travel inside the block inside ensure_minimum_duration
        travel_to(actual_duration.from_now) if actual_duration && actual_duration > 0
      end
    end
  end
end
