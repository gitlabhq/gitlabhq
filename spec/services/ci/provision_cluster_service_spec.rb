require 'spec_helper'

describe Ci::ProvisionClusterService do
  describe '#execute' do
    let(:cluster) { create(:gcp_cluster) }
    let(:operation) { spy }

    shared_examples 'error' do
      it 'sets an error to cluster object' do
        described_class.new.execute(cluster)

        expect(cluster.reload).to be_errored
      end
    end

    context 'when suceeded to request provision' do
      before do
        allow_any_instance_of(GoogleApi::CloudPlatform::Client)
          .to receive(:projects_zones_clusters_create).and_return(operation)
      end

      context 'when operation status is RUNNING' do
        before do
          allow(operation).to receive(:status).and_return('RUNNING')
        end

        context 'when suceeded to parse gcp operation id' do
          before do
            allow_any_instance_of(GoogleApi::CloudPlatform::Client)
              .to receive(:parse_operation_id).and_return('operation-123')
          end

          context 'when cluster status is scheduled' do
            before do
              allow_any_instance_of(GoogleApi::CloudPlatform::Client)
                .to receive(:parse_operation_id).and_return('operation-123')
            end

            it 'schedules a worker for status minitoring' do
              expect(WaitForClusterCreationWorker).to receive(:perform_in)

              described_class.new.execute(cluster)
            end
          end

          context 'when cluster status is creating' do
            before do
              cluster.make_creating!
            end

            it_behaves_like 'error'
          end
        end

        context 'when failed to parse gcp operation id' do
          before do
            allow_any_instance_of(GoogleApi::CloudPlatform::Client)
              .to receive(:parse_operation_id).and_return(nil)
          end

          it_behaves_like 'error'
        end
      end

      context 'when operation status is others' do
        before do
          allow(operation).to receive(:status).and_return('others')
        end

        it_behaves_like 'error'
      end
    end

    context 'when failed to request provision' do
      let(:error) { Google::Apis::ServerError.new('a') }

      before do
        allow_any_instance_of(GoogleApi::CloudPlatform::Client)
          .to receive(:projects_zones_clusters_create).and_raise(error)
      end

      it_behaves_like 'error'
    end
  end
end
