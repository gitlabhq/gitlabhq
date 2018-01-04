require 'rails_helper'

describe Clusters::Applications::Prometheus do
  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to validate_presence_of(:cluster) }

  include_examples 'cluster application specs', described_class

  describe 'transition to installed' do
    let(:project) { create(:project) }
    let(:cluster) { create(:cluster, projects: [project]) }
    let(:prometheus_service) { double('prometheus_service') }

    subject { create(:clusters_applications_prometheus, :installing, cluster: cluster) }

    before do
      allow(project).to receive(:prometheus_service).and_return prometheus_service
    end

    it 'ensures Prometheus service is activated' do
      expect(prometheus_service).to receive(:update).with(active: true)

      subject.make_installed
    end
  end

  describe "#chart_values_file" do
    subject { create(:clusters_applications_prometheus).chart_values_file }

    it 'should return chart values file path' do
      expect(subject).to eq("#{Rails.root}/vendor/prometheus/values.yaml")
    end
  end
end
