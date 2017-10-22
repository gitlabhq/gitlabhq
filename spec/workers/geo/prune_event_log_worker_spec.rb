require 'spec_helper'

describe Geo::PruneEventLogWorker, :geo do
  include ::EE::GeoHelpers

  subject(:worker) { described_class.new }
  set(:primary) { create(:geo_node, :primary, host: 'primary-geo-node') }
  set(:secondary) { create(:geo_node) }

  before do
    allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(true)
  end

  describe '#perform' do
    context 'current node secondary' do
      before do
        stub_current_geo_node(secondary)
      end

      it 'does nothing' do
        expect(worker).not_to receive(:try_obtain_lease)

        worker.perform
      end
    end

    context 'current node primary' do
      before do
        stub_current_geo_node(primary)
      end

      it 'logs error when it cannot obtain lease' do
        allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { nil }

        expect(worker).to receive(:log_error).with('Cannot obtain an exclusive lease. There must be another worker already in execution.')

        worker.perform
      end

      context 'no secondary nodes' do
        before do
          secondary.destroy
        end

        it 'deletes everything from the Geo event log' do
          expect(Geo::EventLog).to receive(:delete_all)

          worker.perform
        end
      end

      context 'multiple secondary nodes' do
        set(:secondary2) { create(:geo_node) }
        let(:healthy_status) { build(:geo_node_status, :healthy) }
        let(:unhealthy_status) { build(:geo_node_status, :unhealthy) }

        it 'contacts all secondary nodes for their status' do
          expect_any_instance_of(Geo::NodeStatusService).to receive(:call).twice { healthy_status }
          expect(Geo::EventLog).to receive(:delete_all)

          worker.perform
        end

        it 'aborts when there are unhealthy nodes' do
          expect_any_instance_of(Geo::NodeStatusService).to receive(:call) { healthy_status }
          expect_any_instance_of(Geo::NodeStatusService).to receive(:call) { unhealthy_status }
          expect(Geo::EventLog).not_to receive(:delete_all)

          worker.perform
        end

        it 'takes the integer-minimum value of all nodes' do
          allow_any_instance_of(Geo::NodeStatusService).to receive(:call) { build(:geo_node_status, :healthy, cursor_last_event_id: 3) }
          allow_any_instance_of(Geo::NodeStatusService).to receive(:call) { build(:geo_node_status, :healthy, cursor_last_event_id: 10) }
          expect(Geo::EventLog).not_to receive(:delete_all).with(['id < ?', 3])

          worker.perform
        end
      end
    end
  end

  describe '#log_error' do
    it 'calls the Geo logger' do
      expect(Gitlab::Geo::Logger).to receive(:error)

      worker.log_error('Something is wrong')
    end
  end
end
