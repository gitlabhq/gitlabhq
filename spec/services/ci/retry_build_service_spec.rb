require 'spec_helper'

describe Ci::RetryBuildService, :services do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:build) { create(:ci_build, pipeline: pipeline) }

  let(:service) do
    described_class.new(project, user)
  end

  shared_examples 'build duplication' do
    let(:build) do
      create(:ci_build, :failed, :artifacts_expired, :erased, :trace,
             :queued, :coverage, pipeline: pipeline)
    end

    describe 'clone attributes' do
      described_class::CLONE_ATTRIBUTES.each do |attribute|
        it "clones #{attribute} build attribute" do
          expect(new_build.send(attribute)).to eq build.send(attribute)
        end
      end
    end

    describe 'reject attributes' do
      described_class::REJECT_ATTRIBUTES.each do |attribute|
        it "does not clone #{attribute} build attribute" do
          expect(new_build.send(attribute)).not_to eq build.send(attribute)
        end
      end
    end

    it 'has correct number of known attributes' do
      attributes =
        described_class::CLONE_ATTRIBUTES +
        described_class::IGNORE_ATTRIBUTES +
        described_class::REJECT_ATTRIBUTES

      expect(build.attributes.size).to eq(attributes.size)
    end
  end

  describe '#execute' do
    let(:new_build) { service.execute(build) }

    context 'when user has ability to execute build' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'build duplication'

      it 'creates a new build that represents the old one' do
        expect(new_build.name).to eq build.name
      end

      it 'enqueues the new build' do
        expect(new_build).to be_pending
      end

      it 'resolves todos for old build that failed' do
        expect(MergeRequests::AddTodoWhenBuildFailsService)
          .to receive_message_chain(:new, :close)

        service.execute(build)
      end

      context 'when there are subsequent builds that are skipped' do
        let!(:subsequent_build) do
          create(:ci_build, :skipped, stage_idx: 1, pipeline: pipeline)
        end

        it 'resumes pipeline processing in subsequent stages' do
          service.execute(build)

          expect(subsequent_build.reload).to be_created
        end
      end
    end

    context 'when user does not have ability to execute build' do
      it 'raises an error' do
        expect { service.execute(build) }
          .to raise_error Gitlab::Access::AccessDeniedError
      end
    end
  end

  describe '#reprocess' do
    let(:new_build) { service.reprocess(build) }

    context 'when user has ability to execute build' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'build duplication'

      it 'creates a new build that represents the old one' do
        expect(new_build.name).to eq build.name
      end

      it 'does not enqueue the new build' do
        expect(new_build).to be_created
      end
    end

    context 'when user does not have ability to execute build' do
      it 'raises an error' do
        expect { service.reprocess(build) }
          .to raise_error Gitlab::Access::AccessDeniedError
      end
    end
  end
end
