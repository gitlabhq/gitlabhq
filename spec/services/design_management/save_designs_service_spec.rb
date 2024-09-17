# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DesignManagement::SaveDesignsService, feature_category: :design_management do
  include DesignManagementTestHelpers
  include ConcurrentHelpers

  let_it_be_with_reload(:issue) { create(:issue) }

  let(:project) { issue.project }
  let(:user) {  create(:user) }
  let(:files) { [rails_sample] }
  let(:design_repository) { project.find_or_create_design_management_repository.repository }

  let(:rails_sample_name) { 'rails_sample.jpg' }
  let(:rails_sample) { sample_image(rails_sample_name) }
  let(:dk_png) { sample_image('dk.png') }

  def sample_image(filename)
    fixture_file_upload("spec/fixtures/#{filename}")
  end

  def commit_count
    design_repository.expire_statistics_caches
    design_repository.expire_root_ref_cache
    design_repository.commit_count
  end

  before do
    issue.instance_variable_set(:@design_collection, nil) # reload collection for each example

    if issue.design_collection.repository.exists?
      issue.design_collection.repository.expire_all_method_caches
      issue.design_collection.repository.raw.delete_all_refs_except([Gitlab::Git::SHA1_BLANK_SHA])
    end

    project.add_reporter(user)

    allow(DesignManagement::NewVersionWorker)
      .to receive(:perform_async).with(Integer, false).and_return(nil)
  end

  def run_service(files_to_upload = nil)
    design_files = files_to_upload || files
    design_files.each(&:rewind)

    service = described_class.new(project, user, issue: issue, files: design_files)
    service.execute
  end

  # Randomly alter the content of files.
  # This allows the files to be updated by the service, as unmodified
  # files are rejected.
  def touch_files(files_to_touch = nil)
    design_files = files_to_touch || files

    design_files.each do |f|
      f.tempfile.write(SecureRandom.random_bytes)
    end
  end

  let(:response) { run_service }

  shared_examples 'a service error' do
    it 'returns an error', :aggregate_failures do
      expect(response).to match(a_hash_including(status: :error))
    end
  end

  shared_examples 'an execution error' do
    it 'returns an error', :aggregate_failures do
      expect { service.execute }.to raise_error(some_error)
    end
  end

  describe '#execute' do
    context 'when the feature is not available' do
      before do
        enable_design_management(false)
      end

      it_behaves_like 'a service error'

      it 'does not create an event in the activity stream' do
        expect { run_service }.not_to change { Event.count }
      end
    end

    context 'when the feature is available' do
      before do
        enable_design_management(true)
      end

      describe 'repository existence' do
        def repository_exists
          # Expire the memoized value as the service creates it's own instance
          design_repository.expire_exists_cache
          design_repository.exists?
        end

        it 'is ensured when the service runs' do
          run_service

          expect(repository_exists).to be true
        end
      end

      it 'creates a commit, an event in the activity stream and updates the creation count', :aggregate_failures do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_designs_added_action)
                                                                           .with(author: user, project: project)

        expect { run_service }
          .to change { Event.count }.by(1)
          .and change { Event.for_design.created_action.count }.by(1)

        expect(design_repository.commit).to have_attributes(
          author: user,
          message: include(rails_sample_name)
        )
      end

      it 'tracks internal events and increments usage metrics', :clean_gitlab_redis_shared_state do
        expect { run_service }
          .to trigger_internal_events(Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_DESIGNS_ADDED)
            .with(user: user, project: project, category: 'InternalEventTracking')
          .and trigger_internal_events('create_design_management_design')
            .with(user: user, project: project)
          .and increment_usage_metrics(
            'redis_hll_counters.issues_edit.g_project_management_issue_designs_added_monthly',
            'redis_hll_counters.issues_edit.g_project_management_issue_designs_added_weekly',
            'redis_hll_counters.issues_edit.issues_edit_total_unique_counts_monthly',
            'redis_hll_counters.issues_edit.issues_edit_total_unique_counts_weekly',
            'counts.design_management_designs_create'
          )
      end

      it 'can run the same command in parallel',
        quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/450483' do
        parellism = 4

        blocks = Array.new(parellism).map do
          unique_files = [RenameableUpload.unique_file('rails_sample.jpg')]

          -> { run_service(unique_files) }
        end

        expect { run_parallel(blocks) }.to change(DesignManagement::Version, :count).by(parellism)
      end

      context 'when the design collection is in the process of being copied', :clean_gitlab_redis_shared_state do
        before do
          issue.design_collection.start_copy!
        end

        it_behaves_like 'a service error'
      end

      context 'when the design collection has a copy error', :clean_gitlab_redis_shared_state do
        before do
          issue.design_collection.copy_state = 'error'
          issue.design_collection.send(:set_stored_copy_state!)
        end

        it 'resets the copy state' do
          expect { run_service }.to change { issue.design_collection.copy_state }.from('error').to('ready')
        end
      end

      describe 'the response' do
        it 'includes designs with the expected properties' do
          updated_designs = response[:designs]

          expect(updated_designs).to all(have_attributes(diff_refs: be_present))
          expect(updated_designs.size).to eq(1)
          expect(updated_designs.first.versions.size).to eq(1)
          expect(updated_designs.first.versions.first.author).to eq(user)
        end
      end

      describe 'saving the file to LFS' do
        before do
          expect_next_instance_of(Lfs::FileTransformer) do |transformer|
            expect(transformer).to receive(:lfs_file?).and_return(true)
          end
        end

        it 'saves the design to LFS and saves the repository_type of the LfsObjectsProject as design' do
          expect { run_service }
            .to change { LfsObject.count }.by(1)
            .and change { project.lfs_objects_projects.count }.from(0).to(1)

          expect(project.lfs_objects_projects.first.repository_type).to eq('design')
        end
      end

      context 'when HEAD branch is different from master' do
        before do
          stub_feature_flags(main_branch_over_master: true)
        end

        it 'does not raise an exception during update' do
          run_service

          expect { run_service }.not_to raise_error
        end
      end

      context 'when a design is being updated' do
        before do
          # This setup triggers multiple different internal events, so we'll trigger
          # the irrelevant events farther in the past to better test the metrics
          travel_to(2.months.ago) do
            run_service
            touch_files
          end
        end

        it 'creates a new version for the existing design and updates the file' do
          expect(issue.designs.size).to eq(1)
          expect(DesignManagement::Version.for_designs(issue.designs).size).to eq(1)

          updated_designs = response[:designs]

          expect(updated_designs.size).to eq(1)
          expect(updated_designs.first.versions.size).to eq(2)
        end

        it 'tracks internal events and increments usage metrics', :clean_gitlab_redis_shared_state do
          expect { run_service }
            .to trigger_internal_events(Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_DESIGNS_MODIFIED)
              .with(user: user, project: project, category: 'InternalEventTracking')
            .and trigger_internal_events('update_design_management_design')
              .with(user: user, project: project)
            .and increment_usage_metrics(
              'redis_hll_counters.issues_edit.g_project_management_issue_designs_modified_monthly',
              'redis_hll_counters.issues_edit.g_project_management_issue_designs_modified_weekly',
              'redis_hll_counters.issues_edit.issues_edit_total_unique_counts_monthly',
              'redis_hll_counters.issues_edit.issues_edit_total_unique_counts_weekly',
              'counts.design_management_designs_update'
            )
        end

        it 'records the correct events' do
          expect { run_service }
            .to change { Event.count }.by(1)
            .and change { Event.for_design.updated_action.count }.by(1)
        end

        context 'when uploading a new design' do
          it 'does not link the new version to the existing design' do
            existing_design = issue.designs.first

            updated_designs = run_service([dk_png])[:designs]

            expect(existing_design.versions.reload.size).to eq(1)
            expect(updated_designs.size).to eq(1)
            expect(updated_designs.first.versions.size).to eq(1)
          end
        end

        context 'when detecting content type' do
          it 'detects content type when feature flag is enabled' do
            expect_next_instance_of(::Lfs::FileTransformer) do |file_transformer|
              expect(file_transformer).to receive(:new_file)
                .with(anything, anything, hash_including(detect_content_type: true)).and_call_original
            end

            run_service
          end

          it 'skips content type detection when feature flag is disabled' do
            stub_feature_flags(design_management_allow_dangerous_images: false)
            expect_next_instance_of(::Lfs::FileTransformer) do |file_transformer|
              expect(file_transformer).to receive(:new_file)
                .with(anything, anything, hash_including(detect_content_type: false)).and_call_original
            end

            run_service
          end
        end
      end

      context 'when a design has not changed since its previous version' do
        before do
          run_service
        end

        it 'does not create a new version, and returns the design in `skipped_designs`' do
          response = nil

          expect { response = run_service }.not_to change { issue.design_versions.count }

          expect(response[:designs]).to be_empty
          expect(response[:skipped_designs].size).to eq(1)
        end
      end

      context 'when doing a mixture of updates and creations' do
        let(:files) { [rails_sample, dk_png] }

        before do
          travel_to(2.months.ago) do
            # Create just the first one, which we will later update.
            run_service([files.first])
            touch_files([files.first])
          end
        end

        it 'has the correct side-effects' do
          expect(DesignManagement::NewVersionWorker)
            .to receive(:perform_async).once.with(Integer, false).and_return(nil)

          expect { run_service }
            .to change { Event.count }.by(2)
            .and change { Event.for_design.count }.by(2)
            .and change { Event.created_action.count }.by(1)
            .and change { Event.updated_action.count }.by(1)
            .and change { commit_count }.by(1)
        end

        it 'tracks internal events and increments usage metrics', :clean_gitlab_redis_shared_state do
          expect { run_service }
            .to trigger_internal_events(
              Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_DESIGNS_ADDED,
              Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_DESIGNS_MODIFIED
            ).with(user: user, project: project, category: 'InternalEventTracking')
            .and trigger_internal_events(
              'create_design_management_design',
              'update_design_management_design'
            ).with(user: user, project: project)
            .and increment_usage_metrics(
              'redis_hll_counters.issues_edit.g_project_management_issue_designs_modified_monthly',
              'redis_hll_counters.issues_edit.g_project_management_issue_designs_modified_weekly',
              'redis_hll_counters.issues_edit.g_project_management_issue_designs_added_monthly',
              'redis_hll_counters.issues_edit.g_project_management_issue_designs_added_weekly',
              'redis_hll_counters.issues_edit.issues_edit_total_unique_counts_monthly',
              'redis_hll_counters.issues_edit.issues_edit_total_unique_counts_weekly',
              'counts.design_management_designs_update',
              'counts.design_management_designs_create'
            )
        end
      end

      context 'when uploading multiple files' do
        let(:files) { [rails_sample, dk_png] }

        it 'returns information about both designs in the response' do
          expect(response).to include(designs: have_attributes(size: 2), status: :success)
        end

        it 'has the correct side-effects', :request_store, :clean_gitlab_redis_shared_state do
          service = described_class.new(project, user, issue: issue, files: files)

          # Some unrelated calls that are usually cached or happen only once
          # We expect:
          #  - An exists?
          #  - a check for existing blobs
          #  - default branch
          #  - an after_commit callback on LfsObjectsProject
          design_repository.create_if_not_exists
          design_repository.has_visible_content?

          expect(DesignManagement::NewVersionWorker)
            .to receive(:perform_async).once.with(Integer, false).and_return(nil)

          expect { service.execute }
            .to change { issue.designs.count }.from(0).to(2)
            .and change { DesignManagement::Version.count }.by(1)
            .and change { Gitlab::GitalyClient.get_request_count }.by(4)
            .and change { commit_count }.by(1)
            .and trigger_internal_events(Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_DESIGNS_ADDED)
              .twice.with(user: user, project: project, category: 'InternalEventTracking')
            .and trigger_internal_events('create_design_management_design')
              .twice.with(user: user, project: project)
            .and increment_usage_metrics(
              'redis_hll_counters.issues_edit.g_project_management_issue_designs_added_monthly',
              'redis_hll_counters.issues_edit.g_project_management_issue_designs_added_weekly',
              'redis_hll_counters.issues_edit.issues_edit_total_unique_counts_monthly',
              'redis_hll_counters.issues_edit.issues_edit_total_unique_counts_weekly'
            ).and increment_usage_metrics('counts.design_management_designs_create').by(2)
        end

        context 'when uploading too many files' do
          let(:files) { Array.new(DesignManagement::SaveDesignsService::MAX_FILES + 1) { dk_png } }

          it 'returns the correct error' do
            expect(response[:message]).to match(/only \d+ files are allowed simultaneously/i)
          end
        end

        context 'when uploading duplicate files' do
          let(:files) { [rails_sample, dk_png, rails_sample] }

          it 'returns the correct error' do
            expect(response[:message]).to match('Duplicate filenames are not allowed!')
          end
        end
      end

      context 'when the user is not allowed to upload designs' do
        let(:user) { build_stubbed(:user, id: non_existing_record_id) }

        it_behaves_like 'a service error'
      end

      describe 'failure modes' do
        let(:service) { described_class.new(project, user, issue: issue, files: files) }
        let(:response) { service.execute }

        before do
          expect(service).to receive(:run_actions).and_raise(some_error)
        end

        context 'when creating the commit fails' do
          let(:some_error) { Gitlab::Git::BaseError }

          it_behaves_like 'an execution error'
        end

        context 'when creating the versions fails' do
          let(:some_error) { ActiveRecord::RecordInvalid }

          it_behaves_like 'a service error'
        end
      end

      context "when a design already existed in the repo but we didn't know about it in the database" do
        let(:filename) { rails_sample_name }

        before do
          path = File.join(build(:design, issue: issue, filename: filename).full_path)
          design_repository.create_if_not_exists
          design_repository.create_file(
            user,
            path, 'something fake',
            branch_name: project.default_branch_or_main,
            message: 'Somehow created without being tracked in db'
          )
        end

        it 'creates the design and a new version for it' do
          first_updated_design = response[:designs].first

          expect(first_updated_design.filename).to eq(filename)
          expect(first_updated_design.versions.size).to eq(1)
        end
      end

      describe 'scalability', skip: 'See: https://gitlab.com/gitlab-org/gitlab/-/issues/213169' do
        before do
          run_service([sample_image('banana_sample.gif')]) # ensure project, issue, etc are created
        end

        it 'runs the same queries for all requests, regardless of number of files' do
          one = [dk_png]
          two = [rails_sample, dk_png]

          baseline = ActiveRecord::QueryRecorder.new { run_service(one) }

          expect { run_service(two) }.not_to exceed_query_limit(baseline)
        end
      end
    end
  end
end
