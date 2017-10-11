require 'spec_helper'
require 'google/apis'

describe Ci::FetchGcpOperationService do
  describe '#execute' do
    let(:cluster) { create(:gcp_cluster) }
    let(:operation) { double }

    context 'when suceeded' do
      before do
        allow_any_instance_of(GoogleApi::CloudPlatform::Client)
          .to receive(:projects_zones_operations).and_return(operation)
      end

      it 'fetch the gcp operaion' do
        expect { |b| described_class.new.execute(cluster, &b) }
          .to yield_with_args(operation)
      end
    end

    context 'when raises an error' do
      let(:error) { Google::Apis::ServerError.new('a') }

      before do
        allow_any_instance_of(GoogleApi::CloudPlatform::Client)
          .to receive(:projects_zones_operations).and_raise(error)
      end

      it 'sets an error to cluster object' do
        expect { |b| described_class.new.execute(cluster, &b) }
          .not_to yield_with_args
        expect(cluster.reload).to be_errored
      end
    end
  end
end
