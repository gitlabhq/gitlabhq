# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Prometheus::Metrics::DestroyService do
  let(:metric) { create(:prometheus_metric) }

  subject { described_class.new(metric) }

  it 'destroys metric' do
    subject.execute

    expect(PrometheusMetric.find_by(id: metric.id)).to be_nil
  end

  context 'when metric has a prometheus alert associated' do
    it 'schedules a prometheus alert update' do
      create(:prometheus_alert, project: metric.project, prometheus_metric: metric)

      schedule_update_service = spy
      allow(::Clusters::Applications::ScheduleUpdateService).to receive(:new).and_return(schedule_update_service)

      subject.execute

      expect(schedule_update_service).to have_received(:execute)
    end
  end
end
