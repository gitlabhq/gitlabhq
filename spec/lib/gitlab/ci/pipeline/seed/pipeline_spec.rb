# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Seed::Pipeline do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let(:seed_context) { double(pipeline: pipeline, root_variables: []) }

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

  before do
    stub_feature_flags(ci_same_stage_job_needs: false)
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

        expect(seed.errors).to contain_exactly(
          "'invalid_job' job needs 'non-existent' job, but 'non-existent' is not in any previous stage")
      end
    end
  end

  describe '#deployments_count' do
    it 'counts the jobs having an environment associated' do
      expect(seed.deployments_count).to eq(2)
    end
  end
end
