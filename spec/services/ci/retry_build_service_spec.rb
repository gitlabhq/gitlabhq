require 'spec_helper'

describe Ci::RetryBuildService do
  set(:user) { create(:user) }
  set(:project) { create(:project) }
  set(:pipeline) { create(:ci_pipeline, project: project) }

  let(:stage) do
    Ci::Stage.create!(project: project, pipeline: pipeline, name: 'test')
  end

  let(:build) { create(:ci_build, pipeline: pipeline, stage_id: stage.id) }

  let(:service) do
    described_class.new(project, user)
  end

  CLONE_ACCESSORS = described_class::CLONE_ACCESSORS

  REJECT_ACCESSORS =
    %i[id status user token coverage trace runner artifacts_expire_at
       artifacts_file artifacts_metadata artifacts_size created_at
       updated_at started_at finished_at queued_at erased_by
       erased_at auto_canceled_by job_artifacts job_artifacts_archive
       job_artifacts_metadata job_artifacts_trace].freeze

  IGNORE_ACCESSORS =
    %i[type lock_version target_url base_tags trace_sections
       commit_id deployments erased_by_id last_deployment project_id
       runner_id tag_taggings taggings tags trigger_request_id
       user_id auto_canceled_by_id retried failure_reason
       artifacts_file_store artifacts_metadata_store
       metadata chunks].freeze

  shared_examples 'build duplication' do
    let(:another_pipeline) { create(:ci_empty_pipeline, project: project) }

    let(:build) do
      create(:ci_build, :failed, :artifacts, :expired, :erased,
             :queued, :coverage, :tags, :allowed_to_fail, :on_tag,
             :triggered, :trace_artifact, :teardown_environment,
             description: 'my-job', stage: 'test', stage_id: stage.id,
             pipeline: pipeline, auto_canceled_by: another_pipeline)
    end

    before do
      # Make sure that build has both `stage_id` and `stage` because FactoryBot
      # can reset one of the fields when assigning another. We plan to deprecate
      # and remove legacy `stage` column in the future.
      build.update_attributes(stage: 'test', stage_id: stage.id)
    end

    describe 'clone accessors' do
      CLONE_ACCESSORS.each do |attribute|
        it "clones #{attribute} build attribute" do
          expect(build.send(attribute)).not_to be_nil
          expect(new_build.send(attribute)).not_to be_nil
          expect(new_build.send(attribute)).to eq build.send(attribute)
        end
      end

      context 'when job has nullified protected' do
        before do
          build.update_attribute(:protected, nil)
        end

        it "clones protected build attribute" do
          expect(new_build.protected).to be_nil
          expect(new_build.protected).to eq build.protected
        end
      end
    end

    describe 'reject acessors' do
      REJECT_ACCESSORS.each do |attribute|
        it "does not clone #{attribute} build attribute" do
          expect(new_build.send(attribute)).not_to eq build.send(attribute)
        end
      end
    end

    it 'has correct number of known attributes' do
      known_accessors = CLONE_ACCESSORS + REJECT_ACCESSORS + IGNORE_ACCESSORS

      # :tag_list is a special case, this accessor does not exist
      # in reflected associations, comes from `act_as_taggable` and
      # we use it to copy tags, instead of reusing tags.
      #
      current_accessors =
        Ci::Build.attribute_names.map(&:to_sym) +
        Ci::Build.reflect_on_all_associations.map(&:name) +
        [:tag_list]

      current_accessors.uniq!

      expect(known_accessors).to contain_exactly(*current_accessors)
    end
  end

  describe '#execute' do
    let(:new_build) { service.execute(build) }

    context 'when user has ability to execute build' do
      before do
        stub_not_protect_default_branch

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
          create(:ci_build, :skipped, stage_idx: 2,
                                      pipeline: pipeline,
                                      stage: 'deploy')
        end

        it 'resumes pipeline processing in a subsequent stage' do
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
    let(:new_build) { service.reprocess!(build) }

    context 'when user has ability to execute build' do
      before do
        stub_not_protect_default_branch

        project.add_developer(user)
      end

      it_behaves_like 'build duplication'

      it 'creates a new build that represents the old one' do
        expect(new_build.name).to eq build.name
      end

      it 'does not enqueue the new build' do
        expect(new_build).to be_created
      end

      it 'does mark old build as retried in the database and on the instance' do
        expect(new_build).to be_latest
        expect(build).to be_retried
        expect(build.reload).to be_retried
      end
    end

    context 'when user does not have ability to execute build' do
      it 'raises an error' do
        expect { service.reprocess!(build) }
          .to raise_error Gitlab::Access::AccessDeniedError
      end
    end
  end
end
