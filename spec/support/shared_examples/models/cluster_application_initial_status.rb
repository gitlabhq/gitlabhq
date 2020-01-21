# frozen_string_literal: true

shared_examples 'cluster application initial status specs' do
  describe '#status' do
    let(:cluster) { create(:cluster, :provided_by_gcp) }

    subject { described_class.new(cluster: cluster) }

    context 'local tiller feature flag is disabled' do
      before do
        stub_feature_flags(managed_apps_local_tiller: false)
      end

      it 'sets a default status' do
        expect(subject.status_name).to be(:not_installable)
      end
    end

    context 'local tiller feature flag is enabled' do
      before do
        stub_feature_flags(managed_apps_local_tiller: true)
      end

      it 'sets a default status' do
        expect(subject.status_name).to be(:installable)
      end
    end

    context 'when application helm is scheduled' do
      before do
        stub_feature_flags(managed_apps_local_tiller: false)

        create(:clusters_applications_helm, :scheduled, cluster: cluster)
      end

      it 'defaults to :not_installable' do
        expect(subject.status_name).to be(:not_installable)
      end
    end

    context 'when application helm is installed' do
      before do
        create(:clusters_applications_helm, :installed, cluster: cluster)
      end

      it 'sets a default status' do
        expect(subject.status_name).to be(:installable)
      end
    end
  end
end
