shared_examples 'cluster application status specs' do |application_name|
  describe '#status' do
    let(:cluster) { create(:cluster, :provided_by_gcp) }

    subject { described_class.new(cluster: cluster) }

    it 'sets a default status' do
      expect(subject.status_name).to be(:not_installable)
    end

    context 'when application helm is scheduled' do
      before do
        create(:clusters_applications_helm, :scheduled, cluster: cluster)
      end

      it 'defaults to :not_installable' do
        expect(subject.status_name).to be(:not_installable)
      end
    end

    context 'when application is scheduled' do
      before do
        create(:clusters_applications_helm, :installed, cluster: cluster)
      end

      it 'sets a default status' do
        expect(subject.status_name).to be(:installable)
      end
    end
  end
end
