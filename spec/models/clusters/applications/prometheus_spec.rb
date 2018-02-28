require 'rails_helper'

describe Clusters::Applications::Prometheus do
  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to validate_presence_of(:cluster) }

  include_examples 'cluster application specs', described_class

  describe "#chart_values_file" do
    subject { create(:clusters_applications_prometheus).chart_values_file }

    it 'should return chart values file path' do
      expect(subject).to eq("#{Rails.root}/vendor/prometheus/values.yaml")
    end
  end
end
