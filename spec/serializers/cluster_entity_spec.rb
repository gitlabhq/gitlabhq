# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClusterEntity do
  include Gitlab::Routing.url_helpers

  describe '#as_json' do
    let(:user) { nil }
    let(:request) { EntityRequest.new({ current_user: user }) }

    subject { described_class.new(cluster, request: request).as_json }

    context 'when provider type is gcp' do
      let(:cluster) { create(:cluster, :instance, provider_type: :gcp, provider_gcp: provider) }

      context 'when status is creating' do
        let(:provider) { create(:cluster_provider_gcp, :creating) }

        it 'has corresponded data' do
          expect(subject[:status]).to eq(:creating)
          expect(subject[:status_reason]).to be_nil
        end
      end

      context 'when status is errored' do
        let(:provider) { create(:cluster_provider_gcp, :errored) }

        it 'has corresponded data' do
          expect(subject[:status]).to eq(:errored)
          expect(subject[:status_reason]).to eq(provider.status_reason)
        end
      end
    end

    context 'when provider type is user' do
      let(:cluster) { create(:cluster, :instance, provider_type: :user) }

      it 'has corresponded data' do
        expect(subject[:status]).to eq(:created)
        expect(subject[:status_reason]).to be_nil
      end
    end

    context 'when no application has been installed' do
      let(:cluster) { create(:cluster, :instance) }

      subject { described_class.new(cluster, request: request).as_json[:applications]}

      it 'contains helm as not_installable' do
        expect(subject).not_to be_empty

        helm = subject[0]
        expect(helm[:name]).to eq('helm')
        expect(helm[:status]).to eq(:not_installable)
      end
    end

    context 'gitlab_managed_apps_logs_path' do
      let(:cluster) { create(:cluster, :project) }
      let(:user) { create(:user) }

      subject { described_class.new(cluster, request: request).as_json }

      before do
        allow_next_instance_of(Clusters::ClusterPresenter) do |presenter|
          allow(presenter).to receive(:show_path).and_return(nil)
        end
      end

      it 'return projects log explorer path' do
        log_explorer_path = project_logs_path(cluster.project, cluster_id: cluster.id)

        expect_next_instance_of(Clusters::ClusterPresenter, cluster, current_user: user) do |presenter|
          expect(presenter).to receive(:gitlab_managed_apps_logs_path).and_return(log_explorer_path)
        end

        expect(subject[:gitlab_managed_apps_logs_path]).to eq(log_explorer_path)
      end
    end

    context 'enable_advanced_logs_querying' do
      let(:cluster) { create(:cluster, :project) }
      let(:user) { create(:user) }

      subject { described_class.new(cluster, request: request).as_json }

      context 'elastic stack is not installed on cluster' do
        it 'returns false' do
          expect(subject[:enable_advanced_logs_querying]).to be false
        end
      end

      context 'elastic stack is enabled on cluster' do
        it 'returns true' do
          create(:clusters_integrations_elastic_stack, cluster: cluster)

          expect(subject[:enable_advanced_logs_querying]).to be true
        end
      end
    end
  end
end
