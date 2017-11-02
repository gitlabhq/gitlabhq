require 'spec_helper'

describe Geo::MetricsUpdateService, :geo do
  include ::EE::GeoHelpers

  subject { described_class.new }

  let(:timestamp) { Time.now.to_i }

  before do
    allow(Gitlab::Metrics).to receive(:prometheus_metrics_enabled?).and_return(true)
  end

  describe '#execute' do
    before do
      data = {
        health: 'OK',
        db_replication_lag_seconds: 0,
        repositories_count: 10,
        repositories_synced_count: 1,
        repositories_failed_count: 2,
        lfs_objects_count: 100,
        lfs_objects_synced_count: 50,
        lfs_objects_failed_count: 12,
        attachments_count: 30,
        attachments_synced_count: 30,
        attachments_failed_count: 25,
        last_event_id: 2,
        last_event_timestamp: timestamp,
        cursor_last_event_id: 1,
        cursor_last_event_timestamp: timestamp
      }
      request = double(success?: true, parsed_response: data.stringify_keys, code: 200)
      allow(Geo::NodeStatusService).to receive(:get).and_return(request)
    end

    context 'when node is the primary' do
      set(:primary) { create(:geo_node, :primary) }
      set(:secondary) { create(:geo_node) }
      set(:another_secondary) { create(:geo_node) }

      before do
        stub_current_geo_node(primary)
      end

      it 'attempts to retrieve metrics from all nodes' do
        subject.execute

        expect(Gitlab::Metrics.provide_metric(:geo_db_replication_lag_seconds).values.count).to eq(2)
        expect(Gitlab::Metrics.provide_metric(:geo_repositories).values.count).to eq(2)
        expect(Gitlab::Metrics.provide_metric(:geo_repositories).get({ url: secondary.url })).to eq(10)
        expect(Gitlab::Metrics.provide_metric(:geo_repositories).get({ url: secondary.url })).to eq(10)
      end
    end

    context 'when node is a secondary' do
      set(:secondary) { create(:geo_node) }

      subject { described_class.new }

      before do
        stub_current_geo_node(secondary)
      end

      it 'adds gauges for various metrics' do
        subject.execute

        expect(metric_value(:geo_db_replication_lag_seconds)).to eq(0)
        expect(metric_value(:geo_repositories)).to eq(10)
        expect(metric_value(:geo_repositories_synced)).to eq(1)
        expect(metric_value(:geo_repositories_failed)).to eq(2)
        expect(metric_value(:geo_lfs_objects)).to eq(100)
        expect(metric_value(:geo_lfs_objects_synced)).to eq(50)
        expect(metric_value(:geo_lfs_objects_failed)).to eq(12)
        expect(metric_value(:geo_attachments)).to eq(30)
        expect(metric_value(:geo_attachments_synced)).to eq(30)
        expect(metric_value(:geo_attachments_failed)).to eq(25)
        expect(metric_value(:geo_last_event_id)).to eq(2)
        expect(metric_value(:geo_last_event_timestamp)).to eq(timestamp.to_i)
        expect(metric_value(:geo_cursor_last_event_id)).to eq(1)
        expect(metric_value(:geo_cursor_last_event_timestamp)).to eq(timestamp.to_i)
        expect(metric_value(:geo_status_last_updated_timestamp)).to be_truthy
      end

      it 'increments a counter when metrics fail to retrieve' do
        allow(subject).to receive(:node_status).and_return(GeoNodeStatus.new(success: false))

        # Run once to get the gauge set
        subject.execute

        expect { subject.execute }.to change { metric_value(:geo_status_failed_total) }.by(1)
      end

      def metric_value(metric_name)
        Gitlab::Metrics.provide_metric(metric_name).get({ url: secondary.url })
      end
    end
  end
end
