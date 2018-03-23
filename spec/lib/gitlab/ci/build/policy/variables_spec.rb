require 'spec_helper'

describe Gitlab::Ci::Build::Policy::Variables do
  let(:pipeline) { build_stubbed(:ci_empty_pipeline, ref: 'master') }
  let(:build) { build_stubbed(:ci_build, pipeline: pipeline, ref: 'master') }

  before do
    pipeline.variables.build(key: 'CI_PROJECT_NAME', value: '')
  end

  describe '#satisfied_by?' do
    it 'is satisfied by a defined and existing variable' do
      policy = described_class.new(['$CI_PROJECT_ID', '$UNDEFINED'])

      expect(policy).to be_satisfied_by(pipeline, build)
    end

    it 'is not satisfied by an overriden empty variable' do
      policy = described_class.new(['$CI_PROJECT_NAME'])

      expect(policy).not_to be_satisfied_by(pipeline, build)
    end

    it 'is satisfied by a truthy pipeline expression' do
      policy = described_class.new([%($CI_PIPELINE_SOURCE == "#{pipeline.source}")])

      expect(policy).to be_satisfied_by(pipeline, build)
    end

    it 'is not satisfied by a falsy pipeline expression' do
      policy = described_class.new([%($CI_PIPELINE_SOURCE == "invalid source")])

      expect(policy).not_to be_satisfied_by(pipeline, build)
    end

    it 'is satisfied by a truthy expression using undefined variable' do
      policy = described_class.new(['$UNDEFINED', '$UNDEFINED == null'])

      expect(policy).to be_satisfied_by(pipeline, build)
    end
  end
end
