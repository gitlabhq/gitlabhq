# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::ManagedResource, feature_category: :deployment_management do
  it { is_expected.to belong_to(:build).class_name('Ci::Build') }
  it { is_expected.to belong_to(:cluster_agent).class_name('Clusters::Agent') }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:environment) }

  it { is_expected.to validate_length_of(:template_name).is_at_most(1024) }

  describe '.order_id_desc' do
    let_it_be(:project) { create(:project) }
    let_it_be(:environment) { create(:environment, project:) }
    let_it_be(:cluster_agent) { create(:cluster_agent, project:) }
    let_it_be(:build1) { create(:ci_build, project:) }
    let_it_be(:build2) { create(:ci_build, project:) }
    let_it_be(:build3) { create(:ci_build, project:) }

    let!(:record1) do
      create(:managed_resource, id: 111, build: build1, project: project, environment: environment,
        cluster_agent: cluster_agent)
    end

    let!(:record3) do
      create(:managed_resource, id: 333, build: build3, project: project, environment: environment,
        cluster_agent: cluster_agent)
    end

    let!(:record2) do
      create(:managed_resource, id: 222, build: build2, project: project, environment: environment,
        cluster_agent: cluster_agent)
    end

    subject { described_class.order_id_desc }

    it { is_expected.to eq([record3, record2, record1]) }
  end
end
