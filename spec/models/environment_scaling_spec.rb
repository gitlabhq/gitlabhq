require 'spec_helper'

describe EnvironmentScaling do
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:environment) { create(:environment, project: project) }
  let(:environment_scaling) { create(:environment_scaling, environment: environment) }

  it { is_expected.to belong_to(:environment) }

  it { is_expected.to validate_presence_of(:replicas) }
  it { is_expected.to validate_numericality_of(:replicas).only_integer }

  describe '#available?' do
    subject { environment_scaling.available? }

    context 'when there is a conflicting secret variable' do
      context 'when the conflicting variable is a project variable' do
        before do
          environment_scaling.environment.project.variables.create(key: 'PRODUCTION_REPLICAS', value: '2')
        end

        it { is_expected.to be false }
      end

      context 'when the conflicting variable is a group variable' do
        before do
          environment_scaling.environment.project.group.variables.create(key: "#{environment.name.upcase}_REPLICAS", value: '2')
        end

        it { is_expected.to be false }
      end
    end

    context 'when there is no conflicting secret variable' do
      it { is_expected.to be true }
    end
  end

  describe '#predefined_variables' do
    subject { environment_scaling.predefined_variables }

    it { is_expected.to include({ key: "#{environment_scaling.environment.name.upcase}_REPLICAS", value: environment_scaling.replicas }) }
  end
end
