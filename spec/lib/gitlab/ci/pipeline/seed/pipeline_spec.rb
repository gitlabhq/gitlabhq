# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Seed::Pipeline, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let(:root_variables) { [] }

  let(:seed_context) { Gitlab::Ci::Pipeline::Seed::Context.new(pipeline, root_variables: root_variables) }

  let(:stages_attributes) do
    [
      {
        name: 'build',
        index: 0,
        builds: [
          { name: 'init', scheduling_type: :stage },
          { name: 'build', scheduling_type: :stage }
        ]
      },
      {
        name: 'test',
        index: 1,
        builds: [
          { name: 'rspec', scheduling_type: :stage },
          { name: 'staging', scheduling_type: :stage, environment: 'staging' },
          { name: 'deploy', scheduling_type: :stage, environment: 'production' }
        ]
      }
    ]
  end

  subject(:seed) do
    described_class.new(seed_context, stages_attributes)
  end

  describe '#stages' do
    it 'returns the stage resources' do
      stages = seed.stages

      expect(stages).to all(be_a(Ci::Stage))
      expect(stages.map(&:name)).to contain_exactly('build', 'test')
    end
  end

  describe '#size' do
    it 'returns the number of jobs' do
      expect(seed.size).to eq(5)
    end
  end

  describe '#errors' do
    context 'when attributes are valid' do
      it 'returns nil' do
        expect(seed.errors).to be_nil
      end
    end

    context 'when attributes are not valid' do
      it 'returns the errors' do
        stages_attributes[0][:builds] << {
          name: 'invalid_job',
          scheduling_type: :dag,
          needs_attributes: [{ name: 'non-existent', artifacts: true }]
        }

        expect(seed.errors.first).to include(
          "'invalid_job' job needs 'non-existent' job, but 'non-existent' does not exist in the pipeline")
      end
    end
  end

  describe '#excluded_stage_errors' do
    let(:invalid_rule) do
      [{ changes: { paths: ['README.md'], compare_to: 'invalid-ref' } }]
    end

    context 'when every stage has at least one included build' do
      it 'returns nil' do
        expect(seed.excluded_stage_errors).to be_nil
      end
    end

    context 'when a stage is dropped because its only build raised a rules error' do
      before do
        stages_attributes << {
          name: 'scan',
          index: 2,
          builds: [{ name: 'scan', scheduling_type: :stage, rules: invalid_rule }]
        }
      end

      it 'returns the errors the dropped stage was carrying' do
        expect(seed.excluded_stage_errors).to contain_exactly(
          a_string_including('rules:changes:compare_to is not a valid ref')
        )
      end

      it 'does not report them through #errors' do
        expect(seed.errors).to be_nil
      end

      it 'leaves the dropped stage out of #stages' do
        expect(seed.stages.map(&:name)).to contain_exactly('build', 'test')
      end
    end

    context 'when a stage is dropped because all of its builds raised a rules error' do
      before do
        stages_attributes << {
          name: 'scan',
          index: 2,
          builds: [
            { name: 'scan_one', scheduling_type: :stage, rules: invalid_rule },
            { name: 'scan_two', scheduling_type: :stage, rules: invalid_rule }
          ]
        }
      end

      it 'returns the errors of every build in the dropped stage' do
        expect(seed.excluded_stage_errors.size).to eq(2)
      end
    end

    context 'when the stage survives because another build is included' do
      before do
        stages_attributes << {
          name: 'scan',
          index: 2,
          builds: [
            { name: 'scan', scheduling_type: :stage, rules: invalid_rule },
            { name: 'sibling', scheduling_type: :stage }
          ]
        }
      end

      it 'returns nil and reports the error through #errors instead' do
        expect(seed.excluded_stage_errors).to be_nil
        expect(seed.errors).to contain_exactly(
          a_string_including('rules:changes:compare_to is not a valid ref')
        )
      end
    end
  end

  describe '#deployments_count' do
    it 'counts the jobs having an environment associated' do
      expect(seed.deployments_count).to eq(2)
    end
  end

  describe '#root_variables' do
    let(:root_variables) { %w[var1 value1] }

    it 'returns root_variables' do
      expect(seed.root_variables).to eq(root_variables)
    end
  end
end
