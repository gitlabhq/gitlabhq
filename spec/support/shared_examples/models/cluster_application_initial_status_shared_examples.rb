# frozen_string_literal: true

RSpec.shared_examples 'cluster application initial status specs' do
  describe '#status' do
    let(:cluster) { create(:cluster, :provided_by_gcp) }

    subject { described_class.new(cluster: cluster) }

    it 'sets a default status' do
      expect(subject.status_name).to be(:installable)
    end
  end
end
