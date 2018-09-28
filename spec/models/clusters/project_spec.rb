require 'spec_helper'

describe Clusters::Project do
  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to belong_to(:project) }

  describe '#namespace' do
    let(:project) { create(:project, name: 'hello') }
    let(:cluster) { create(:cluster, :provided_by_user, projects: [project]) }
    let(:cluster_project) { cluster.cluster_projects.first }

    it 'defaults to project_name-project-id' do
      expect(cluster_project.namespace).to eq "hello-#{project.id}"
    end
  end
end
