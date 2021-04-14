# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::ClientMetrics do
  shared_examples "a metrics middleware" do
    context "with mocked prometheus" do
      let(:enqueued_jobs_metric) { double('enqueued jobs metric', increment: true) }

      before do
        allow(Gitlab::Metrics).to receive(:counter).with(described_class::ENQUEUED, anything).and_return(enqueued_jobs_metric)
      end

      describe '#call' do
        it 'yields block' do
          expect { |b| subject.call(worker_class, job, :test, double, &b) }.to yield_control.once
        end

        it 'increments enqueued jobs metric with correct labels when worker is a string of the class' do
          expect(enqueued_jobs_metric).to receive(:increment).with(labels, 1)

          subject.call(worker_class.to_s, job, :test, double) { nil }
        end

        it 'increments enqueued jobs metric with correct labels' do
          expect(enqueued_jobs_metric).to receive(:increment).with(labels, 1)

          subject.call(worker_class, job, :test, double) { nil }
        end
      end
    end
  end

  it_behaves_like 'metrics middleware with worker attribution'
end
