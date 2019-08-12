# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Cluster::PumaWorkerKillerObserver do
  let(:counter) { Gitlab::Metrics::NullMetric.instance }

  before do
    allow(Gitlab::Metrics).to receive(:counter)
      .with(any_args)
      .and_return(counter)
  end

  describe '#callback' do
    subject { described_class.new }

    it 'increments timeout counter' do
      worker = double(index: 0)

      expect(counter).to receive(:increment)

      subject.callback.call(worker)
    end
  end
end
