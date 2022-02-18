# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HasEnvironmentScope do
  let_it_be(:project) { create(:project) }

  subject { build(:ci_variable) }

  it { is_expected.to allow_value('*').for(:environment_scope) }
  it { is_expected.to allow_value('review/*').for(:environment_scope) }
  it { is_expected.not_to allow_value('').for(:environment_scope) }
  it { is_expected.not_to allow_value('!!()()').for(:environment_scope) }

  it do
    is_expected.to validate_uniqueness_of(:key)
      .scoped_to(:project_id, :environment_scope)
      .with_message(/\(\w+\) has already been taken/)
  end

  describe '.on_environment' do
    it 'returns scoped objects' do
      variable1 = create(:ci_variable, project: project, environment_scope: '*')
      variable2 = create(:ci_variable, project: project, environment_scope: 'product/*')
      create(:ci_variable, project: project, environment_scope: 'staging/*')

      expect(project.variables.on_environment('product/canary-1')).to eq([variable1, variable2])
    end

    it 'returns only the most relevant object if relevant_only is true' do
      create(:ci_variable, project: project, environment_scope: '*')
      variable2 = create(:ci_variable, project: project, environment_scope: 'product/*')
      create(:ci_variable, project: project, environment_scope: 'staging/*')

      expect(project.variables.on_environment('product/canary-1', relevant_only: true)).to eq([variable2])
    end

    it 'returns scopes ordered by lowest precedence first' do
      create(:ci_variable, project: project, environment_scope: '*')
      create(:ci_variable, project: project, environment_scope: 'production*')
      create(:ci_variable, project: project, environment_scope: 'production')

      result = project.variables.on_environment('production').map(&:environment_scope)

      expect(result).to eq(['*', 'production*', 'production'])
    end
  end

  describe '#environment_scope=' do
    context 'when the new environment_scope is nil' do
      it 'strips leading and trailing whitespaces' do
        subject.environment_scope = nil

        expect(subject.environment_scope).to eq('')
      end
    end

    context 'when the new environment_scope has leadind and trailing whitespaces' do
      it 'strips leading and trailing whitespaces' do
        subject.environment_scope = ' * '

        expect(subject.environment_scope).to eq('*')
      end
    end
  end

  describe '.for_environment' do
    subject { project.variables.for_environment(environment) }

    let_it_be(:variable1) do
      create(:ci_variable, project: project, environment_scope: '*')
    end

    let_it_be(:variable2) do
      create(:ci_variable, project: project, environment_scope: 'production/*')
    end

    let_it_be(:variable3) do
      create(:ci_variable, project: project, environment_scope: 'staging/*')
    end

    context 'when the environment is present' do
      let(:environment) { 'production/canary-1' }

      it { is_expected.to eq([variable1, variable2]) }
    end

    context 'when the environment is nil' do
      let(:environment) {}

      it { is_expected.to eq([variable1]) }
    end
  end
end
