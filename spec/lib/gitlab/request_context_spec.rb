# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RequestContext, :request_store, feature_category: :application_instrumentation do
  subject { described_class.instance }

  before do
    allow(subject).to receive(:enabled?).and_return(true)
  end

  it { is_expected.to have_attributes(client_ip: nil, start_thread_cpu_time: nil, request_start_time: nil) }

  describe '.start_request_context' do
    let(:request) { ActionDispatch::Request.new({ 'REMOTE_ADDR' => '1.2.3.4' }) }
    let(:start_request_context) { described_class.start_request_context(request: request) }

    before do
      allow(Gitlab::Metrics::System).to receive(:real_time).and_return(123)
    end

    it 'sets the client IP' do
      expect { start_request_context }.to change { subject.client_ip }.from(nil).to('1.2.3.4')
    end

    it 'sets the spam params' do
      expect { start_request_context }.to change { subject.spam_params }.from(nil).to(::Spam::SpamParams)
    end

    it 'sets the request start time' do
      expect { start_request_context }.to change { subject.request_start_time }.from(nil).to(123)
    end
  end

  describe '.start_thread_context' do
    let(:start_thread_context) { described_class.start_thread_context }

    before do
      allow(Gitlab::Metrics::System).to receive(:thread_cpu_time).and_return(123)
      allow(Gitlab::Memory::Instrumentation).to receive(:start_thread_memory_allocations).and_return(456)
    end

    it 'sets the thread cpu time' do
      expect { start_thread_context }.to change { subject.start_thread_cpu_time }.from(nil).to(123)
    end

    it 'sets the thread memory allocations' do
      expect { start_thread_context }.to change { subject.thread_memory_allocations }.from(nil).to(456)
    end
  end

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
