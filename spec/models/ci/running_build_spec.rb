# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunningBuild do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let(:runner) { create(:ci_runner, :instance_type) }
  let(:build) { create(:ci_build, :running, runner: runner, pipeline: pipeline) }

  describe '.upsert_shared_runner_build!' do
    context 'another pending entry does not exist' do
      it 'creates a new pending entry' do
        result = described_class.upsert_shared_runner_build!(build)

        expect(result.rows.dig(0, 0)).to eq build.id
        expect(build.reload.runtime_metadata).to be_present
      end
    end

    context 'when another queuing entry exists for given build' do
      before do
        create(:ci_running_build, build: build, project: project, runner: runner)
      end

      it 'returns a build id as a result' do
        result = described_class.upsert_shared_runner_build!(build)

        expect(result.rows.dig(0, 0)).to eq build.id
      end
    end

    context 'when build has been picked by a specific runner' do
      let(:runner) { create(:ci_runner, :project) }

      it 'raises an error' do
        expect { described_class.upsert_shared_runner_build!(build) }
          .to raise_error(ArgumentError, 'build has not been picked by a shared runner')
      end
    end

    context 'when build has not been picked by a runner yet' do
      let(:build) { create(:ci_build, pipeline: pipeline) }

      it 'raises an error' do
        expect { described_class.upsert_shared_runner_build!(build) }
          .to raise_error(ArgumentError, 'build has not been picked by a shared runner')
      end
    end
  end
end
