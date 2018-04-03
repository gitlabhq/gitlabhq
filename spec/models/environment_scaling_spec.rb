require 'spec_helper'

describe EnvironmentScaling do
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:environment) { create(:environment, project: project) }
  let(:environment_scaling) { create(:environment_scaling, environment: environment) }

  it { is_expected.to belong_to(:environment) }

  it { is_expected.to validate_presence_of(:replicas) }
  it { is_expected.to validate_numericality_of(:replicas).only_integer }

  describe '.available_for?' do
    subject { described_class.available_for?(environment) }

    context 'when project has a conflicting variable' do
      before do
        project.variables.create(key: 'PRODUCTION_REPLICAS', value: '2')
      end

      it 'should be false' do
        expect(subject).to eq false
      end
    end

    context 'when group has a conflicting variable' do
      before do
        group.variables.create(key: "#{environment.ci_name}_REPLICAS", value: '2')
      end

      it 'should be false' do
        expect(subject).to eq false
      end
    end

    context 'when there is no conflicting variable' do
      it 'should be true' do
        expect(subject).to eq true
      end
    end
  end

  describe '.incompatible_variables_for?' do
    subject { described_class.incompatible_variables_for(environment) }

    it 'returns incompatible variables' do
      expect(subject).to eq(["#{environment.ci_name}_REPLICAS", "PRODUCTION_REPLICAS"])
    end
  end

  describe '#available?' do
    subject { environment_scaling.available? }

    it 'calls the class method for availability' do
      expect(EnvironmentScaling).to receive(:available_for?)

      subject
    end
  end

  describe '#predefined_variables' do
    subject { environment_scaling.predefined_variables }

    it { is_expected.to include({ key: "#{environment_scaling.environment.ci_name}_REPLICAS", value: environment_scaling.replicas }) }
  end
end
