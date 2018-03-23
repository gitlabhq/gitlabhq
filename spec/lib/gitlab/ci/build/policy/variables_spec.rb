require 'spec_helper'

describe Gitlab::Ci::Build::Policy::Variables do
  set(:project) { create(:project) }

  let(:ci_pipeline) do
    build(:ci_empty_pipeline, project: project, ref: 'master')
  end

  let(:ci_build) do
    build(:ci_build, pipeline: ci_pipeline, project: project, ref: 'master')
  end

  before do
    ci_pipeline.variables.build(key: 'CI_PROJECT_NAME', value: '')
  end

  describe '#satisfied_by?' do
    it 'is satisfied by a defined and existing variable' do
      policy = described_class.new(['$CI_PROJECT_ID', '$UNDEFINED'])

      expect(policy).to be_satisfied_by(ci_pipeline, ci_build)
    end

    it 'is not satisfied by an overriden empty variable' do
      policy = described_class.new(['$CI_PROJECT_NAME'])

      expect(policy).not_to be_satisfied_by(ci_pipeline, ci_build)
    end

    it 'is satisfied by a truthy pipeline expression' do
      policy = described_class.new([%($CI_PIPELINE_SOURCE == "#{ci_pipeline.source}")])

      expect(policy).to be_satisfied_by(ci_pipeline, ci_build)
    end

    it 'is not satisfied by a falsy pipeline expression' do
      policy = described_class.new([%($CI_PIPELINE_SOURCE == "invalid source")])

      expect(policy).not_to be_satisfied_by(ci_pipeline, ci_build)
    end

    it 'is satisfied by a truthy expression using undefined variable' do
      policy = described_class.new(['$UNDEFINED', '$UNDEFINED == null'])

      expect(policy).to be_satisfied_by(ci_pipeline, ci_build)
    end

    it 'does not persist neither pipeline nor build' do
      described_class.new('$VAR').satisfied_by?(ci_pipeline, ci_build)

      expect(ci_pipeline).not_to be_persisted
      expect(ci_build).not_to be_persisted
    end

    pending 'test for secret variables'
  end
end
