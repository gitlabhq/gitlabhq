# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Policy::Variables do
  let_it_be(:project) { create(:project) }

  let(:pipeline) do
    build(:ci_empty_pipeline, project: project, ref: 'master', source: :push)
  end

  let(:ci_build) do
    build(:ci_build, pipeline: pipeline, project: project, ref: 'master')
  end

  let(:seed) do
    double('build seed',
      to_resource: ci_build,
      variables: ci_build.scoped_variables
    )
  end

  before do
    pipeline.variables.build(key: 'CI_PROJECT_NAME', value: '')
    pipeline.variables.build(key: 'MY_VARIABLE', value: 'my-var')
  end

  describe '#satisfied_by?' do
    it 'is satisfied by at least one matching statement' do
      policy = described_class.new(['$CI_PROJECT_ID', '$UNDEFINED'])

      expect(policy).to be_satisfied_by(pipeline, seed)
    end

    it 'is satisfied by a matching pipeline variable' do
      policy = described_class.new(['$MY_VARIABLE'])

      expect(policy).to be_satisfied_by(pipeline, seed)
    end

    it 'is not satisfied by an overridden empty variable' do
      policy = described_class.new(['$CI_PROJECT_NAME'])

      expect(policy).not_to be_satisfied_by(pipeline, seed)
    end

    it 'is satisfied by a truthy pipeline expression' do
      policy = described_class.new([%($CI_PIPELINE_SOURCE == "push")])

      expect(policy).to be_satisfied_by(pipeline, seed)
    end

    it 'is not satisfied by a falsy pipeline expression' do
      policy = described_class.new([%($CI_PIPELINE_SOURCE == "invalid source")])

      expect(policy).not_to be_satisfied_by(pipeline, seed)
    end

    it 'is satisfied by a truthy expression using undefined variable' do
      policy = described_class.new(['$UNDEFINED == null'])

      expect(policy).to be_satisfied_by(pipeline, seed)
    end

    it 'is not satisfied by a falsy expression using undefined variable' do
      policy = described_class.new(['$UNDEFINED'])

      expect(policy).not_to be_satisfied_by(pipeline, seed)
    end

    it 'allows to evaluate regular CI variables' do
      create(:ci_variable, project: project, key: 'SECRET', value: 'my secret')

      policy = described_class.new(["$SECRET == 'my secret'"])

      expect(policy).to be_satisfied_by(pipeline, seed)
    end

    it 'does not persist neither pipeline nor build' do
      described_class.new('$VAR').satisfied_by?(pipeline, seed)

      expect(pipeline).not_to be_persisted
      expect(seed.to_resource).not_to be_persisted
    end

    context 'when a bridge job is used' do
      let(:bridge) do
        build(:ci_bridge, pipeline: pipeline, project: project, ref: 'master')
      end

      let(:seed) do
        double('bridge seed',
          to_resource: bridge,
          variables: ci_build.scoped_variables
        )
      end

      it 'is satisfied by a matching expression for a bridge job' do
        policy = described_class.new(['$MY_VARIABLE'])

        expect(policy).to be_satisfied_by(pipeline, seed)
      end
    end

    context 'when using project ci variables in environment scope' do
      let(:ci_build) do
        build(:ci_build, pipeline: pipeline,
                         project: project,
                         ref: 'master',
                         stage: 'review',
                         environment: 'test/$CI_JOB_STAGE/1')
      end

      before do
        create(:ci_variable, project: project,
                             key: 'SCOPED_VARIABLE',
                             value: 'my-value-1')

        create(:ci_variable, project: project,
                             key: 'SCOPED_VARIABLE',
                             value: 'my-value-2',
                             environment_scope: 'test/review/*')
      end

      it 'is satisfied by scoped variable match' do
        policy = described_class.new(['$SCOPED_VARIABLE == "my-value-2"'])

        expect(policy).to be_satisfied_by(pipeline, seed)
      end

      it 'is not satisfied when matching against overridden variable' do
        policy = described_class.new(['$SCOPED_VARIABLE == "my-value-1"'])

        expect(policy).not_to be_satisfied_by(pipeline, seed)
      end
    end
  end
end
