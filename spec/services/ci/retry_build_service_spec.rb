require 'spec_helper'

describe Ci::RetryBuildService, :services do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:build) { create(:ci_build, pipeline: pipeline) }

  let(:service) do
    described_class.new(build, user)
  end

  describe '#retry!' do
    let(:new_build) { service.retry! }

    context 'when user has ability to retry build' do
      before do
        project.team << [user, :developer]
      end

      it 'creates a new build that represents the old one' do
        expect(new_build.name).to eq build.name
      end

      it 'enqueues the new build' do
        expect(new_build).to be_pending
      end

      it 'resolves todos for old build that failed' do
        expect(MergeRequests::AddTodoWhenBuildFailsService)
          .to receive_message_chain(:new, :close)

        service.retry!
      end

      context 'when there are subsequent builds that are skipped' do
        let!(:subsequent_build) do
          create(:ci_build, :skipped, stage_idx: 1, pipeline: pipeline)
        end

        it 'resumes pipeline processing in subsequent stages' do
          service.retry!

          expect(subsequent_build.reload).to be_created
        end
      end
    end

    context 'when user does not have ability to retry build' do
      it 'raises an error' do
        expect { service.retry! }
          .to raise_error Gitlab::Access::AccessDeniedError
      end
    end
  end
end
