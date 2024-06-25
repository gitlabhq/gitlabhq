# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:cleanup rake tasks', :silence_stdout do
  before do
    Rake.application.rake_require 'tasks/gitlab/cleanup'
  end

  # A single integration test that is redundant with one part of the
  # Gitlab::Cleanup::ProjectUploads spec.
  #
  # Additionally, this tests DRY_RUN env var values, and the extra line of
  # output that says you can disable DRY_RUN if it's enabled.
  describe 'cleanup:project_uploads' do
    let!(:logger) { double(:logger) }

    before do
      expect(main_object).to receive(:logger).and_return(logger).at_least(:once)

      allow(logger).to receive(:info).at_least(:once)
      allow(logger).to receive(:debug).at_least(:once)
    end

    context 'with a fixable orphaned project upload file' do
      let(:orphaned) { create(:upload, :issuable_upload, :with_file, model: build(:project, :legacy_storage)) }
      let(:new_path) { orphaned.absolute_path }
      let(:path) { File.join(FileUploader.root, 'some', 'wrong', 'location', orphaned.path) }

      before do
        FileUtils.mkdir_p(File.dirname(path))
        FileUtils.mv(new_path, path)
      end

      context 'with DRY_RUN disabled' do
        before do
          stub_env('DRY_RUN', 'false')
        end

        it 'moves the file to its proper location' do
          run_rake_task('gitlab:cleanup:project_uploads')

          expect(File.exist?(path)).to be_falsey
          expect(File.exist?(new_path)).to be_truthy
        end

        it 'logs action as done' do
          expect(logger).to receive(:info).with("Looking for orphaned project uploads to clean up...")
          expect(logger).to receive(:info).with("Did fix #{path} -> #{new_path}")

          run_rake_task('gitlab:cleanup:project_uploads')
        end
      end

      shared_examples_for 'does not move the file' do
        it 'does not move the file' do
          run_rake_task('gitlab:cleanup:project_uploads')

          expect(File.exist?(path)).to be_truthy
          expect(File.exist?(new_path)).to be_falsey
        end

        it 'logs action as able to be done' do
          expect(logger).to receive(:info).with("Looking for orphaned project uploads to clean up. Dry run...")
          expect(logger).to receive(:info).with("Can fix #{path} -> #{new_path}")
          expect(logger).to receive(:info).with(/To clean up these files run this command with DRY_RUN=false/)

          run_rake_task('gitlab:cleanup:project_uploads')
        end
      end

      context 'with DRY_RUN explicitly enabled' do
        before do
          stub_env('DRY_RUN', 'true')
        end

        it_behaves_like 'does not move the file'
      end

      context 'with DRY_RUN set to an unknown value' do
        before do
          stub_env('DRY_RUN', 'foo')
        end

        it_behaves_like 'does not move the file'
      end

      context 'with DRY_RUN unset' do
        it_behaves_like 'does not move the file'
      end
    end
  end

  describe 'gitlab:cleanup:orphan_job_artifact_files' do
    subject(:rake_task) { run_rake_task('gitlab:cleanup:orphan_job_artifact_files') }

    it 'runs the task without errors' do
      expect(Gitlab::Cleanup::OrphanJobArtifactFiles)
        .to receive(:new).and_call_original

      expect { rake_task }.not_to raise_error
    end

    context 'with DRY_RUN set to false' do
      before do
        stub_env('DRY_RUN', 'false')
      end

      it 'passes dry_run correctly' do
        expect(Gitlab::Cleanup::OrphanJobArtifactFiles)
          .to receive(:new)
          .with(dry_run: false,
            niceness: anything,
            logger: anything)
          .and_call_original

        rake_task
      end
    end
  end

  describe 'gitlab:cleanup:orphan_lfs_file_references' do
    subject(:rake_task) { run_rake_task('gitlab:cleanup:orphan_lfs_file_references') }

    let(:project) { create(:project, :repository) }

    before do
      stub_env('PROJECT_ID', project.id)
    end

    it 'runs the task without errors' do
      expect(Gitlab::Cleanup::OrphanLfsFileReferences)
        .to receive(:new).and_call_original

      expect { rake_task }.not_to raise_error
    end

    context 'with DRY_RUN set to false' do
      before do
        stub_env('DRY_RUN', 'false')
      end

      it 'passes dry_run correctly' do
        expect(Gitlab::Cleanup::OrphanLfsFileReferences)
          .to receive(:new)
          .with(project,
            dry_run: false,
            logger: anything)
          .and_call_original

        rake_task
      end
    end
  end

  describe 'gitlab:cleanup:orphan_lfs_files' do
    subject(:rake_task) { run_rake_task('gitlab:cleanup:orphan_lfs_files') }

    it 'runs RemoveUnreferencedLfsObjectsWorker' do
      expect_any_instance_of(RemoveUnreferencedLfsObjectsWorker)
        .to receive(:perform)
        .and_call_original

      rake_task
    end
  end

  shared_examples 'does not remove any branches' do
    it 'does not delete any branches' do
      expect(project.repository.raw.find_branch(delete_branch_name)).not_to be_nil
      expect(project.repository.raw.find_branch(keep_branch_name)).not_to be_nil
      expect(project.repository.raw.find_branch('test')).not_to be_nil

      rake_task

      expect(project.repository.raw.find_branch(delete_branch_name)).not_to be_nil
      expect(project.repository.raw.find_branch(keep_branch_name)).not_to be_nil
      expect(project.repository.raw.find_branch('test')).not_to be_nil
    end
  end

  describe 'gitlab:cleanup:remove_missed_source_branches' do
    subject(:rake_task) { run_rake_task('gitlab:cleanup:remove_missed_source_branches', project.id, user.id, dry_run) }

    let(:project) { create(:project, :repository) }
    # Merged merge request with force source branch 1
    # Merged merge request with force source branch 0
    # Non merged merge request with force source branch 1
    # Merged Merge request with delete not in project
    # When can not delete source branch

    let!(:mr1) do
      project.repository.raw.create_branch(delete_branch_name, "master")

      create(:merge_request, :merged, :remove_source_branch, source_project: project, target_project: project,
        source_branch: delete_branch_name, target_branch: 'master')
    end

    let!(:mr2) do
      project.repository.raw.create_branch(keep_branch_name, "master")

      create(:merge_request, :merged, source_project: project, target_project: project, source_branch: keep_branch_name,
        target_branch: 'master')
    end

    let!(:mr3) do
      create(:merge_request, :remove_source_branch, source_project: project, target_project: project,
        source_branch: keep_branch_name, target_branch: 'master')
    end

    let!(:mr4) do
      create(:merge_request, :merged, :remove_source_branch, source_branch: keep_branch_name, target_branch: 'master')
    end

    let!(:mr5) do
      create(:merge_request, :merged, :remove_source_branch, source_branch: 'test', source_project: project,
        target_project: project, target_branch: 'master')
    end

    let!(:protected) do
      create(:protected_branch, :create_branch_on_repository, project: project, name: mr5.source_branch)
    end

    let(:user) { create(:user, :admin) }
    let(:dry_run) { true }
    let(:delete_branch_name) { "to-be-deleted-soon" }
    let(:delete_me_not) { "delete_me_not" }
    let(:keep_branch_name) { "not-to-be-deleted-soon" }

    before do
      project.add_owner(user)
      stub_env('USER_ID', user.id)
      stub_env('PROJECT_ID', project.id)
    end

    context 'when dry run is true' do
      it_behaves_like 'does not remove any branches'

      context 'and when a valid batch size is given' do
        it 'takes into account for the batch size' do
          run_rake_task('gitlab:cleanup:remove_missed_source_branches', project.id, user.id, dry_run)

          stub_env('BATCH_SIZE', '1')
          count_1 = ActiveRecord::QueryRecorder.new do
            run_rake_task('gitlab:cleanup:remove_missed_source_branches', project.id, user.id, dry_run)
          end.count

          stub_env('BATCH_SIZE', '2')
          count_2 = ActiveRecord::QueryRecorder.new do
            run_rake_task('gitlab:cleanup:remove_missed_source_branches', project.id, user.id, dry_run)
          end.count

          expect(count_1).to be > count_2
        end
      end
    end

    context 'when dry run is false' do
      let!(:mr6) do
        project.repository.raw.create_branch(delete_me_not, "master")

        create(:merge_request, :merged, :remove_source_branch, source_project: project, target_project: project,
          source_branch: delete_me_not, target_branch: 'master')
      end

      before do
        stub_env('DRY_RUN', 'false')
      end

      it 'deletes the branches' do
        expect(project.repository.raw.find_branch(delete_branch_name)).not_to be_nil
        expect(project.repository.raw.find_branch(keep_branch_name)).not_to be_nil
        expect(project.repository.raw.find_branch(delete_me_not)).not_to be_nil
        expect(project.repository.raw.find_branch('test')).not_to be_nil

        rake_task

        expect(project.repository.raw.find_branch(delete_branch_name)).to be_nil
        expect(project.repository.raw.find_branch(delete_me_not)).to be_nil
        expect(project.repository.raw.find_branch(keep_branch_name)).not_to be_nil
        expect(project.repository.raw.find_branch('test')).not_to be_nil
      end

      context 'when a limit is set' do
        before do
          stub_env('LIMIT_TO_DELETE', 1)
        end

        it 'deletes only one branch', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/448376' do
          expect(project.repository.raw.find_branch(delete_branch_name)).not_to be_nil
          expect(project.repository.raw.find_branch(keep_branch_name)).not_to be_nil
          expect(project.repository.raw.find_branch(delete_me_not)).not_to be_nil
          expect(project.repository.raw.find_branch('test')).not_to be_nil

          rake_task

          expect(project.repository.raw.find_branch(delete_branch_name)).to be_nil
          expect(project.repository.raw.find_branch(delete_me_not)).not_to be_nil
          expect(project.repository.raw.find_branch(keep_branch_name)).not_to be_nil
          expect(project.repository.raw.find_branch('test')).not_to be_nil
        end
      end

      context 'when the branch has a merged and opened mr' do
        let!(:mr7) do
          project.repository.raw.create_branch(delete_me_not, "master")

          create(:merge_request, :opened, :remove_source_branch, source_project: project, target_project: project,
            source_branch: delete_me_not, target_branch: 'master')
        end

        it 'does not delete the branch of the merged/open mr' do
          expect(project.repository.raw.find_branch(delete_me_not)).not_to be_nil

          rake_task

          expect(project.repository.raw.find_branch(delete_me_not)).not_to be_nil
        end
      end

      context 'when an valid batch size is given' do
        before do
          stub_env('BATCH_SIZE', '1')
        end

        it 'deletes the branches' do
          expect(project.repository.raw.find_branch(delete_branch_name)).not_to be_nil
          expect(project.repository.raw.find_branch(keep_branch_name)).not_to be_nil
          expect(project.repository.raw.find_branch('test')).not_to be_nil

          rake_task

          expect(project.repository.raw.find_branch(delete_branch_name)).to be_nil
          expect(project.repository.raw.find_branch(keep_branch_name)).not_to be_nil
          expect(project.repository.raw.find_branch('test')).not_to be_nil
        end
      end

      context 'when an invalid batch size is given' do
        before do
          stub_env('BATCH_SIZE', '-1')
        end

        it_behaves_like 'does not remove any branches'
      end

      context 'when an invalid limit to delete is given' do
        before do
          stub_env('LIMIT_TO_DELETE', '-1')
        end

        it_behaves_like 'does not remove any branches'
      end
    end
  end

  context 'sessions' do
    describe 'gitlab:cleanup:sessions:active_sessions_lookup_keys', :clean_gitlab_redis_sessions do
      subject(:rake_task) { run_rake_task('gitlab:cleanup:sessions:active_sessions_lookup_keys') }

      let!(:user) { create(:user) }
      let(:existing_session_id) { '5' }

      before do
        Gitlab::Redis::Sessions.with do |redis|
          redis.set(ActiveSession.key_name(user.id, existing_session_id),
            ActiveSession.new(session_id: 'x').dump)
          redis.sadd(ActiveSession.lookup_key_name(user.id), (1..10).to_a)
        end
      end

      it 'runs the task without errors' do
        expect { rake_task }.not_to raise_error
      end

      it 'removes expired active session lookup keys' do
        Gitlab::Redis::Sessions.with do |redis|
          lookup_key = ActiveSession.lookup_key_name(user.id)

          expect { subject }.to change { redis.scard(lookup_key) }.from(10).to(1)
          expect(redis.smembers(lookup_key)).to contain_exactly existing_session_id
        end
      end
    end
  end

  describe 'cleanup:list_orphan_job_artifact_final_objects' do
    let(:filename) { Gitlab::Cleanup::OrphanJobArtifactFinalObjects::GenerateList::DEFAULT_FILENAME }

    subject(:rake_task) { run_rake_task('gitlab:cleanup:list_orphan_job_artifact_final_objects', provider) }

    before do
      stub_artifacts_object_storage
    end

    after do
      File.delete(filename) if File.file?(filename)
    end

    shared_examples_for 'running the cleaner' do
      it 'runs the task without errors' do
        expect(Gitlab::Cleanup::OrphanJobArtifactFinalObjects::GenerateList)
          .to receive(:new)
          .with(
            force_restart: false,
            filename: nil,
            provider: provider,
            logger: anything
          )
          .and_call_original

        expect { rake_task }.not_to raise_error
      end

      context 'with FORCE_RESTART defined' do
        before do
          stub_env('FORCE_RESTART', '1')
        end

        it 'passes force_restart correctly' do
          expect(Gitlab::Cleanup::OrphanJobArtifactFinalObjects::GenerateList)
            .to receive(:new)
            .with(
              force_restart: true,
              filename: nil,
              provider: provider,
              logger: anything
            )
            .and_call_original

          expect { rake_task }.not_to raise_error
        end
      end

      context 'with FILENAME defined' do
        let(:filename) { 'custom_filename.csv' }

        before do
          stub_env('FILENAME', filename)
        end

        it 'passes filename correctly' do
          expect(Gitlab::Cleanup::OrphanJobArtifactFinalObjects::GenerateList)
            .to receive(:new)
            .with(
              force_restart: false,
              filename: filename,
              provider: provider,
              logger: anything
            )
            .and_call_original

          expect { rake_task }.not_to raise_error
        end
      end
    end

    context 'when provider is not specified' do
      let(:provider) { nil }

      it_behaves_like 'running the cleaner'
    end

    context 'when provider is specified' do
      let(:provider) { 'aws' }

      it_behaves_like 'running the cleaner'
    end

    context 'when unsupported provider is given' do
      let(:provider) { 'somethingelse' }

      it 'exits with error' do
        expect { rake_task }.to raise_error(SystemExit)
      end
    end
  end

  describe 'cleanup:delete_orphan_job_artifact_final_objects' do
    let(:orphan_list_filename) { Gitlab::Cleanup::OrphanJobArtifactFinalObjects::GenerateList::DEFAULT_FILENAME }

    let(:deleted_list_filename) do
      [
        Gitlab::Cleanup::OrphanJobArtifactFinalObjects::ProcessList::DELETED_LIST_FILENAME_PREFIX,
        orphan_list_filename
      ].join
    end

    subject(:rake_task) { run_rake_task('gitlab:cleanup:delete_orphan_job_artifact_final_objects') }

    before do
      stub_artifacts_object_storage

      FileUtils.touch(orphan_list_filename)
    end

    after do
      File.delete(orphan_list_filename) if File.file?(orphan_list_filename)
      File.delete(deleted_list_filename) if File.file?(deleted_list_filename)
    end

    it 'runs the task without errors' do
      expect(Gitlab::Cleanup::OrphanJobArtifactFinalObjects::ProcessList)
        .to receive(:new)
        .with(
          force_restart: false,
          filename: nil,
          logger: anything
        )
        .and_call_original

      expect { rake_task }.not_to raise_error
    end

    context 'with FORCE_RESTART defined' do
      before do
        stub_env('FORCE_RESTART', '1')
      end

      it 'passes force_restart correctly' do
        expect(Gitlab::Cleanup::OrphanJobArtifactFinalObjects::ProcessList)
          .to receive(:new)
          .with(
            force_restart: true,
            filename: nil,
            logger: anything
          )
          .and_call_original

        expect { rake_task }.not_to raise_error
      end
    end

    context 'with FILENAME defined' do
      let(:orphan_list_filename) { 'custom_filename.csv' }

      before do
        stub_env('FILENAME', orphan_list_filename)
      end

      it 'passes filename correctly' do
        expect(Gitlab::Cleanup::OrphanJobArtifactFinalObjects::ProcessList)
          .to receive(:new)
          .with(
            force_restart: false,
            filename: orphan_list_filename,
            logger: anything
          )
          .and_call_original

        expect { rake_task }.not_to raise_error
      end
    end
  end

  describe 'cleanup:rollback_deleted_orphan_job_artifact_final_objects' do
    let(:deleted_list_filename) do
      [
        Gitlab::Cleanup::OrphanJobArtifactFinalObjects::ProcessList::DELETED_LIST_FILENAME_PREFIX,
        Gitlab::Cleanup::OrphanJobArtifactFinalObjects::GenerateList::DEFAULT_FILENAME
      ].join
    end

    subject(:rake_task) { run_rake_task('gitlab:cleanup:rollback_deleted_orphan_job_artifact_final_objects') }

    before do
      stub_artifacts_object_storage

      allow(Gitlab.config.artifacts.object_store.connection).to receive(:provider).and_return('Google')

      FileUtils.touch(deleted_list_filename)
    end

    after do
      File.delete(deleted_list_filename) if File.file?(deleted_list_filename)
    end

    it 'runs the task without errors' do
      expect(Gitlab::Cleanup::OrphanJobArtifactFinalObjects::RollbackDeletedObjects)
        .to receive(:new)
        .with(
          force_restart: false,
          filename: nil,
          logger: anything
        )
        .and_call_original

      expect { rake_task }.not_to raise_error
    end

    context 'with FORCE_RESTART defined' do
      before do
        stub_env('FORCE_RESTART', '1')
      end

      it 'passes force_restart correctly' do
        expect(Gitlab::Cleanup::OrphanJobArtifactFinalObjects::RollbackDeletedObjects)
          .to receive(:new)
          .with(
            force_restart: true,
            filename: nil,
            logger: anything
          )
          .and_call_original

        expect { rake_task }.not_to raise_error
      end
    end

    context 'with FILENAME defined' do
      let(:deleted_list_filename) { 'custom_filename.csv' }

      before do
        stub_env('FILENAME', deleted_list_filename)
      end

      it 'passes filename correctly' do
        expect(Gitlab::Cleanup::OrphanJobArtifactFinalObjects::RollbackDeletedObjects)
          .to receive(:new)
          .with(
            force_restart: false,
            filename: deleted_list_filename,
            logger: anything
          )
          .and_call_original

        expect { rake_task }.not_to raise_error
      end
    end
  end
end
