# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::NumbersMetric, feature_category: :service_ping do
  subject do
    described_class.tap do |metric_class|
      metric_class.operation :add
      metric_class.data do |time_frame|
        [
          Gitlab::Usage::Metrics::Instrumentations::CountIssuesMetric.new(time_frame: time_frame).value,
          Gitlab::Usage::Metrics::Instrumentations::CountBoardsMetric.new(time_frame: time_frame).value
        ]
      end
    end.new(time_frame: 'all')
  end

  describe '#value' do
    let_it_be(:issue_1) { create(:issue) }
    let_it_be(:issue_2) { create(:issue) }
    let_it_be(:issue_3) { create(:issue) }
    let_it_be(:issues) { Issue.all }

    let_it_be(:board_1) { create(:board) }
    let_it_be(:boards) { Board.all }

    before do
      allow(Issue.connection).to receive(:transaction_open?).and_return(false)
    end

    it 'calculates a correct result' do
      expect(subject.value).to eq(4)
    end

    context 'with availability defined' do
      subject do
        described_class.tap do |metric_class|
          metric_class.operation :add
          metric_class.data { [1] }
          metric_class.available? { false }
        end.new(time_frame: 'all')
      end

      it 'responds to #available? properly' do
        expect(subject.available?).to eq(false)
      end
    end

    context 'with availability not defined' do
      subject do
        Class.new(described_class) do
          operation :add
          data { [] }
        end.new(time_frame: 'all')
      end

      it 'responds to #available? properly' do
        expect(subject.available?).to eq(true)
      end
    end
  end

  context 'with unimplemented operation method used' do
    subject do
      described_class.tap do |metric_class|
        metric_class.operation :invalid_operation
        metric_class.data { [] }
      end.new(time_frame: 'all')
    end

    it 'raises an error' do
      expect { subject }.to raise_error(described_class::UnimplementedOperationError)
    end
  end
end
