# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServicePing::DevopsReport do
  let_it_be(:data) { { conv_index: {} }.to_json }
  let_it_be(:subject) { described_class.new(Gitlab::Json.parse(data)) }
  let_it_be(:devops_report) { DevOpsReport::Metric.new }

  describe '#execute' do
    context 'when metric is persisted' do
      before do
        allow(DevOpsReport::Metric).to receive(:create).and_return(devops_report)
        allow(devops_report).to receive(:persisted?).and_return(true)
      end

      it 'does not call `track_and_raise_for_dev_exception`' do
        expect(Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception)
        subject.execute
      end
    end

    context 'when metric is not persisted' do
      before do
        allow(DevOpsReport::Metric).to receive(:create).and_return(devops_report)
        allow(devops_report).to receive(:persisted?).and_return(false)
      end

      it 'calls `track_and_raise_for_dev_exception`' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
        subject.execute
      end
    end
  end
end
