require 'spec_helper'

describe Clusters::Project do
  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to belong_to(:project) }

  describe '#default_namespace' do
    let(:cluster_project) { build(:cluster_project) }
    let(:project) { cluster_project.project }

    subject { cluster_project.default_namespace }

    it { is_expected.to eq("#{project.path}-#{project.id}") }
  end
end
