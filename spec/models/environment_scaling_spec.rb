require 'spec_helper'

describe EnvironmentScaling do
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:environment) { create(:environment, project: project) }
  let(:environment_scaling) { create(:environment_scaling, environment: environment) }

  it { is_expected.to belong_to(:environment) }

  it { is_expected.to validate_presence_of(:replicas) }
  it { is_expected.to validate_numericality_of(:replicas).only_integer }

  describe '#predefined_variables' do
    subject { environment_scaling.predefined_variables }

    it { is_expected.to include({ key: "#{environment_scaling.environment.variable_prefix}_REPLICAS", value: environment_scaling.replicas }) }
  end
end
