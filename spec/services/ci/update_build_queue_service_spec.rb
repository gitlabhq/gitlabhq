require 'spec_helper'

describe Ci::UpdateBuildQueueService, :services do
  let(:project) { create(:project) }
  let(:build) { create(:ci_build, pipeline: pipeline) }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  context 'when updating specific runners' do
    let(:runner) { create(:ci_runner) }

    context 'when there are runner that can pick build' do
      before { build.project.runners << runner }

      it 'ticks runner queue value' do
        expect { subject.execute(build) }
          .to change { runner.ensure_runner_queue_value }
      end
    end

    context 'when there are no runners that can pick build' do
      it 'does not tick runner queue value' do
        expect { subject.execute(build) }
          .not_to change { runner.ensure_runner_queue_value }
      end
    end
  end

  context 'when updating shared runners' do
    let(:runner) { create(:ci_runner, :shared) }

    context 'when there are runner that can pick build' do
      it 'ticks runner queue value' do
        expect { subject.execute(build) }
          .to change { runner.ensure_runner_queue_value }
      end
    end

    context 'when there are no runners that can pick build' do
      before { build.tag_list = [:docker] }

      it 'does not tick runner queue value' do
        expect { subject.execute(build) }
          .not_to change { runner.ensure_runner_queue_value }
      end
    end
  end
end
