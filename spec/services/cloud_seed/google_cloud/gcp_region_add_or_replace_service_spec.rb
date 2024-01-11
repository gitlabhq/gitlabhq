# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CloudSeed::GoogleCloud::GcpRegionAddOrReplaceService, feature_category: :deployment_management do
  it 'adds and replaces GCP region vars' do
    project = create(:project, :public)
    service = described_class.new(project)

    service.execute('env_1', 'loc_1')
    service.execute('env_2', 'loc_2')
    service.execute('env_1', 'loc_3')

    list = project.variables.reload.filter { |variable| variable.key == Projects::GoogleCloud::GcpRegionsController::GCP_REGION_CI_VAR_KEY }
    list = list.sort_by(&:environment_scope)

    aggregate_failures 'testing list of gcp regions' do
      expect(list.length).to eq(2)

      # asserting that the first region is replaced
      expect(list.first.environment_scope).to eq('env_1')
      expect(list.first.value).to eq('loc_3')

      expect(list.second.environment_scope).to eq('env_2')
      expect(list.second.value).to eq('loc_2')
    end
  end
end
