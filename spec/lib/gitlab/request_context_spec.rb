# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RequestContext, :request_store do
  subject { described_class.instance }

  before do
    allow(subject).to receive(:enabled?).and_return(true)
  end

  it { is_expected.to have_attributes(client_ip: nil, start_thread_cpu_time: nil, request_start_time: nil) }

  describe '#request_deadline' do
    let(:request_start_time) { 1575982156.206008 }

    before do
      allow(subject).to receive(:request_start_time).and_return(request_start_time)
    end

    it "sets the time to #{Settings.gitlab.max_request_duration_seconds} seconds in the future" do
      expect(subject.request_deadline).to eq(request_start_time + Settings.gitlab.max_request_duration_seconds)
      expect(subject.request_deadline).to be_a(Float)
    end

    it 'returns nil if there is no start time' do
      allow(subject).to receive(:request_start_time).and_return(nil)

      expect(subject.request_deadline).to be_nil
    end
  end

  describe '#ensure_request_deadline_not_exceeded!' do
    it 'does not raise an error when there was no deadline' do
      expect(subject).to receive(:request_deadline).and_return(nil)
      expect { subject.ensure_deadline_not_exceeded! }.not_to raise_error
    end

    it 'does not raise an error if the deadline is in the future' do
      allow(subject).to receive(:request_deadline).and_return(Gitlab::Metrics::System.real_time + 10)

      expect { subject.ensure_deadline_not_exceeded! }.not_to raise_error
    end

    it 'raises an error when the deadline is in the past' do
      allow(subject).to receive(:request_deadline).and_return(Gitlab::Metrics::System.real_time - 10)

      expect { subject.ensure_deadline_not_exceeded! }.to raise_error(described_class::RequestDeadlineExceeded)
    end
  end
end
