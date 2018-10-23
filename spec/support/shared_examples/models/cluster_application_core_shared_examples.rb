shared_examples 'cluster application core specs' do |application_name|
  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to validate_presence_of(:cluster) }

  describe '#name' do
    it 'is .application_name' do
      expect(subject.name).to eq(described_class.application_name)
    end

    it 'is recorded in Clusters::Cluster::APPLICATIONS' do
      expect(Clusters::Cluster::APPLICATIONS[subject.name]).to eq(described_class)
    end
  end
end
