# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::HealthStatus::Signals, feature_category: :database do
  shared_examples 'health status signal' do |subclass, stop_signal, log_signal|
    let(:indicator) { instance_double('Gitlab::Database::HealthStatus::Indicators::PatroniApdex') }
    let(:reason) { 'Test reason' }

    subject { subclass.new(indicator, reason: reason) }

    describe '#log_info?' do
      it 'returns the log signal' do
        expect(subject.log_info?).to eq(log_signal)
      end
    end

    describe '#stop?' do
      it 'returns the stop signal' do
        expect(subject.stop?).to eq(stop_signal)
      end
    end
  end

  context 'with Stop signal it should stop and log' do
    it_behaves_like 'health status signal', described_class::Stop, true, true
  end

  context 'with Normal signal it should not stop and log' do
    it_behaves_like 'health status signal', described_class::Normal, false, false
  end

  context 'with NotAvailable signal it should not stop and log' do
    it_behaves_like 'health status signal', described_class::NotAvailable, false, false
  end

  context 'with Unknown signal it should only log and not stop' do
    it_behaves_like 'health status signal', described_class::Unknown, false, true
  end
end
