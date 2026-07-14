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

    context 'when usage_data_id is present in the response' do
      let(:usage_data_id) { 42 }
      let(:metrics_data) do
        {
          'leader_issues' => 10.2,
          'instance_issues' => 3.2,
          'percentage_issues' => 31.37,
          'leader_notes' => 25.3,
          'instance_notes' => 23.2,
          'leader_milestones' => 16.2,
          'instance_milestones' => 5.5,
          'leader_boards' => 5.2,
          'instance_boards' => 3.2,
          'leader_merge_requests' => 5.2,
          'instance_merge_requests' => 3.2,
          'leader_ci_pipelines' => 25.1,
          'instance_ci_pipelines' => 21.3,
          'leader_environments' => 3.3,
          'instance_environments' => 2.2,
          'leader_deployments' => 41.3,
          'instance_deployments' => 15.2,
          'leader_service_desk_issues' => 15.8,
          'instance_service_desk_issues' => 15.1,
          'usage_data_id' => usage_data_id
        }
      end

      subject(:devops_report_service) { described_class.new({ 'conv_index' => metrics_data }) }

      it 'saves usage_data_id on the metric record' do
        expect { devops_report_service.execute }
          .to change { DevOpsReport::Metric.count }.by(1)

        expect(DevOpsReport::Metric.last.usage_data_id).to eq(usage_data_id)
      end
    end
  end
end
