# frozen_string_literal: true

# Expects `worker_class` to be defined
shared_examples_for 'reenqueuer' do
  subject(:job) { worker_class.new }

  before do
    allow(job).to receive(:sleep) # faster tests
  end

  it 'implements lease_timeout' do
    expect(job.lease_timeout).to be_a(ActiveSupport::Duration)
  end

  describe '#perform' do
    it 'tries to obtain a lease' do
      expect_to_obtain_exclusive_lease(job.lease_key)

      job.perform
    end
  end
end

# Example usage:
#
#   it_behaves_like 'it is rate limited to 1 call per', 5.seconds do
#     subject { described_class.new }
#     let(:rate_limited_method) { subject.perform }
#   end
#
shared_examples_for 'it is rate limited to 1 call per' do |minimum_duration|
  before do
    # Allow Timecop freeze and travel without the block form
    Timecop.safe_mode = false
    Timecop.freeze

    time_travel_during_rate_limited_method(actual_duration)
  end

  after do
    Timecop.return
    Timecop.safe_mode = true
  end

  context 'when the work finishes in 0 seconds' do
    let(:actual_duration) { 0 }

    it 'sleeps exactly the minimum duration' do
      expect(subject).to receive(:sleep).with(a_value_within(0.01).of(minimum_duration))

      rate_limited_method
    end
  end

  context 'when the work finishes in 10% of minimum duration' do
    let(:actual_duration) { 0.1 * minimum_duration }

    it 'sleeps 90% of minimum duration' do
      expect(subject).to receive(:sleep).with(a_value_within(0.01).of(0.9 * minimum_duration))

      rate_limited_method
    end
  end

  context 'when the work finishes in 90% of minimum duration' do
    let(:actual_duration) { 0.9 * minimum_duration }

    it 'sleeps 10% of minimum duration' do
      expect(subject).to receive(:sleep).with(a_value_within(0.01).of(0.1 * minimum_duration))

      rate_limited_method
    end
  end

  context 'when the work finishes exactly at minimum duration' do
    let(:actual_duration) { minimum_duration }

    it 'does not sleep' do
      expect(subject).not_to receive(:sleep)

      rate_limited_method
    end
  end

  context 'when the work takes 10% longer than minimum duration' do
    let(:actual_duration) { 1.1 * minimum_duration }

    it 'does not sleep' do
      expect(subject).not_to receive(:sleep)

      rate_limited_method
    end
  end

  context 'when the work takes twice as long as minimum duration' do
    let(:actual_duration) { 2 * minimum_duration }

    it 'does not sleep' do
      expect(subject).not_to receive(:sleep)

      rate_limited_method
    end
  end

  def time_travel_during_rate_limited_method(actual_duration)
    # Save the original implementation of ensure_minimum_duration
    original_ensure_minimum_duration = subject.method(:ensure_minimum_duration)

    allow(subject).to receive(:ensure_minimum_duration) do |minimum_duration, &block|
      original_ensure_minimum_duration.call(minimum_duration) do
        # Time travel inside the block inside ensure_minimum_duration
        Timecop.travel(actual_duration) if actual_duration && actual_duration > 0
      end
    end
  end
end
