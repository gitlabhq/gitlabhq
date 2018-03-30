require 'spec_helper'

describe EnvironmentScaling do
  let(:environment_scaling) { create(:environment_scaling) }

  it { is_expected.to belong_to(:environment) }

  it { is_expected.to validate_presence_of(:replicas) }
  it { is_expected.to validate_numericality_of(:replicas).only_integer }

  describe '#available?' do
    subject { environment_scaling.available? }

    context 'when there is a conflicting secret variable' do
      before do
        environment_scaling.environment.project.variables.create(key: 'PRODUCTION_REPLICAS', value: '2')
      end

      it { is_expected.to be false }
    end

    context 'when there is no conflicting secret variable' do
      it { is_expected.to be true }
    end
  end

  describe '#predefined_variables' do
    subject { environment_scaling.predefined_variables }

    it { is_expected.to include({ key: 'PRODUCTION_REPLICAS', value: environment_scaling.replicas }) }
  end
end
