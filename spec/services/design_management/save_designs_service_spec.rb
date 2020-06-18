# frozen_string_literal: true
require 'spec_helper'

describe DesignManagement::SaveDesignsService do
  include DesignManagementTestHelpers
  include ConcurrentHelpers

  let_it_be(:developer) { create(:user) }
  let(:project) { issue.project }
  let(:issue) { create(:issue) }
  let(:user) { developer }
  let(:files) { [rails_sample] }
  let(:design_repository) { ::Gitlab::GlRepository::DESIGN.repository_resolver.call(project) }
  let(:rails_sample_name) { 'rails_sample.jpg' }
  let(:rails_sample) { sample_image(rails_sample_name) }
  let(:dk_png) { sample_image('dk.png') }

  def sample_image(filename)
    fixture_file_upload("spec/fixtures/#{filename}")
  end

  before do
    project.add_developer(developer)
  end

  def run_service(files_to_upload = nil)
    design_files = files_to_upload || files
    design_files.each(&:rewind)

    service = described_class.new(project, user,
                                  issue: issue,
                                  files: design_files)
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

        it 'creates a design repository when it did not exist' do
          expect { run_service }.to change { repository_exists }.from(false).to(true)
        end
      end

      it 'updates the creation count' do
        counter = Gitlab::UsageDataCounters::DesignsCounter
        expect { run_service }.to change { counter.read(:create) }.by(1)
      end

      it 'creates an event in the activity stream' do
        expect { run_service }
          .to change { Event.count }.by(1)
          .and change { Event.for_design.created_action.count }.by(1)
      end

      it 'creates a commit in the repository' do
        run_service

        expect(design_repository.commit).to have_attributes(
          author: user,
          message: include(rails_sample_name)
        )
      end

      it 'can run the same command in parallel' do
        blocks = Array.new(10).map do
          unique_files = %w(rails_sample.jpg dk.png)
                          .map { |name| RenameableUpload.unique_file(name) }

          -> { run_service(unique_files) }
        end

        expect { run_parallel(blocks) }.to change(DesignManagement::Version, :count).by(10)
      end

      it 'causes diff_refs not to be nil' do
        expect(response).to include(
          designs: all(have_attributes(diff_refs: be_present))
        )
      end

      it 'creates a design & a version for the filename if it did not exist' do
        expect(issue.designs.size).to eq(0)

        updated_designs = response[:designs]

        expect(updated_designs.size).to eq(1)
        expect(updated_designs.first.versions.size).to eq(1)
      end

      it 'saves the user as the author' do
        updated_designs = response[:designs]

        expect(updated_designs.first.versions.first.author).to eq(user)
      end

      describe 'saving the file to LFS' do
        before do
          expect_next_instance_of(Lfs::FileTransformer) do |transformer|
            expect(transformer).to receive(:lfs_file?).and_return(true)
          end
        end

        it 'saves the design to LFS' do
          expect { run_service }.to change { LfsObject.count }.by(1)
        end

        it 'saves the repository_type of the LfsObjectsProject as design' do
          expect do
            run_service
          end.to change { project.lfs_objects_projects.count }.from(0).to(1)

          expect(project.lfs_objects_projects.first.repository_type).to eq('design')
        end
      end

      context 'when a design is being updated' do
        before do
          run_service
          touch_files
        end

        it 'creates a new version for the existing design and updates the file' do
          expect(issue.designs.size).to eq(1)
          expect(DesignManagement::Version.for_designs(issue.designs).size).to eq(1)

          updated_designs = response[:designs]

          expect(updated_designs.size).to eq(1)
          expect(updated_designs.first.versions.size).to eq(2)
        end

        it 'records the correct events' do
          counter = Gitlab::UsageDataCounters::DesignsCounter
          expect { run_service }
            .to change { counter.read(:update) }.by(1)
            .and change { Event.count }.by(1)
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
      end

      context 'when a design has not changed since its previous version' do
        before do
          run_service
        end

        it 'does not create a new version' do
          expect { run_service }.not_to change { issue.design_versions.count }
        end

        it 'returns the design in `skipped_designs` instead of `designs`' do
          response = run_service

          expect(response[:designs]).to be_empty
          expect(response[:skipped_designs].size).to eq(1)
        end
      end

      context 'when doing a mixture of updates and creations' do
        let(:files) { [rails_sample, dk_png] }

        before do
          # Create just the first one, which we will later update.
          run_service([files.first])
          touch_files([files.first])
        end

        it 'counts one creation and one update' do
          counter = Gitlab::UsageDataCounters::DesignsCounter
          expect { run_service }
            .to change { counter.read(:create) }.by(1)
            .and change { counter.read(:update) }.by(1)
        end

        it 'creates the correct activity stream events' do
          expect { run_service }
            .to change { Event.count }.by(2)
            .and change { Event.for_design.count }.by(2)
            .and change { Event.created_action.count }.by(1)
            .and change { Event.updated_action.count }.by(1)
        end

        it 'creates a single commit' do
          commit_count = -> do
            design_repository.expire_all_method_caches
            design_repository.commit_count
          end

          expect { run_service }.to change { commit_count.call }.by(1)
        end

        it 'enqueues just one new version worker' do
          expect(::DesignManagement::NewVersionWorker)
            .to receive(:perform_async).once.with(Integer)

          run_service
        end
      end

      context 'when uploading multiple files' do
        let(:files) { [rails_sample, dk_png] }

        it 'returns information about both designs in the response' do
          expect(response).to include(designs: have_attributes(size: 2), status: :success)
        end

        it 'creates 2 designs with a single version' do
          expect { run_service }.to change { issue.designs.count }.from(0).to(2)

          expect(DesignManagement::Version.for_designs(issue.designs).size).to eq(1)
        end

        it 'increments the creation count by 2' do
          counter = Gitlab::UsageDataCounters::DesignsCounter
          expect { run_service }.to change { counter.read(:create) }.by 2
        end

        it 'enqueues a new version worker' do
          expect(::DesignManagement::NewVersionWorker)
            .to receive(:perform_async).once.with(Integer)

          run_service
        end

        it 'creates a single commit' do
          commit_count = -> do
            design_repository.expire_all_method_caches
            design_repository.commit_count
          end

          expect { run_service }.to change { commit_count.call }.by(1)
        end

        it 'only does 5 gitaly calls', :request_store, :sidekiq_might_not_need_inline do
          allow(::DesignManagement::NewVersionWorker).to receive(:perform_async).with(Integer)
          service = described_class.new(project, user, issue: issue, files: files)
          # Some unrelated calls that are usually cached or happen only once
          service.__send__(:repository).create_if_not_exists
          service.__send__(:repository).has_visible_content?

          request_count = -> { Gitlab::GitalyClient.get_request_count }

          # An exists?, a check for existing blobs, default branch, an after_commit
          # callback on LfsObjectsProject
          expect { service.execute }.to change(&request_count).by(4)
        end

        context 'when uploading too many files' do
          let(:files) { Array.new(DesignManagement::SaveDesignsService::MAX_FILES + 1) { dk_png } }

          it 'returns the correct error' do
            expect(response[:message]).to match(/only \d+ files are allowed simultaneously/i)
          end
        end
      end

      context 'when the user is not allowed to upload designs' do
        let(:user) { create(:user) }

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
          design_repository.create_file(user, path, 'something fake',
                                        branch_name: 'master',
                                        message: 'Somehow created without being tracked in db')
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
