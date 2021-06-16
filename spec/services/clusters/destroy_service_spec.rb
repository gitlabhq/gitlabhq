# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::DestroyService do
  describe '#execute' do
    subject { described_class.new(cluster.user, params).execute(cluster) }

    let!(:cluster) { create(:cluster, :project, :provided_by_user) }

    context 'when correct params' do
      shared_examples 'only removes cluster' do
        it 'does not start cleanup' do
          expect(cluster).not_to receive(:start_cleanup)
          subject
        end

        it 'destroys the cluster' do
          subject
          expect { cluster.reload }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      context 'when params are empty' do
        let(:params) { {} }

        it_behaves_like 'only removes cluster'
      end

      context 'when cleanup param is false' do
        let(:params) { { cleanup: 'false' } }

        it_behaves_like 'only removes cluster'
      end

      context 'when cleanup param is true' do
        let(:params) { { cleanup: 'true' } }

        before do
          allow(Clusters::Cleanup::ProjectNamespaceWorker).to receive(:perform_async)
        end

        it 'does not destroy cluster' do
          subject
          expect(Clusters::Cluster.where(id: cluster.id).exists?).not_to be_falsey
        end

        it 'transition cluster#cleanup_status from cleanup_not_started to cleanup_removing_project_namespaces' do
          expect { subject }.to change { cluster.cleanup_status_name }
            .from(:cleanup_not_started)
            .to(:cleanup_removing_project_namespaces)
        end
      end
    end
  end
end
