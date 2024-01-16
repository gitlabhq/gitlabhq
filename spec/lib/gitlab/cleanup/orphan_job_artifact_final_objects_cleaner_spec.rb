# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cleanup::OrphanJobArtifactFinalObjectsCleaner, :orphan_final_artifacts_cleanup, :clean_gitlab_redis_shared_state, feature_category: :build_artifacts do
  describe '#run!' do
    let(:cleaner) do
      described_class.new(
        provider: specified_provider,
        force_restart: force_restart,
        dry_run: dry_run
      )
    end

    let(:dry_run) { true }
    let(:force_restart) { false }
    let(:remote_directory) { 'artifacts' }
    let(:bucket_prefix) { nil }

    subject(:run) { cleaner.run! }

    before do
      stub_const('Gitlab::Cleanup::OrphanJobArtifactFinalObjects::Paginators::BasePaginator::BATCH_SIZE', 2)

      Rake.application.rake_require 'tasks/gitlab/cleanup'

      Gitlab.config.artifacts.object_store.tap do |config|
        config[:remote_directory] = remote_directory
        config[:bucket_prefix] = bucket_prefix
      end

      allow(Gitlab::AppLogger).to receive(:info)
    end

    shared_examples_for 'cleaning up orphan final job artifact objects' do
      let(:fog_connection) do
        stub_object_storage_uploader(
          config: Gitlab.config.artifacts.object_store,
          uploader: JobArtifactUploader,
          direct_upload: true
        )
      end

      let!(:orphan_final_object_1) { create_fog_file }
      let!(:orphan_final_object_2) { create_fog_file }
      let!(:orphan_non_final_object) { create_fog_file(final: false) }

      let!(:non_orphan_final_object_1) do
        create_fog_file.tap do |file|
          create(:ci_job_artifact, file_final_path: path_without_bucket_prefix(file.key))
        end
      end

      let!(:non_orphan_final_object_2) do
        create_fog_file.tap do |file|
          create(:ci_job_artifact, file_final_path: path_without_bucket_prefix(file.key))
        end
      end

      shared_context 'when resuming from marker' do
        let(:dummy_error) { Class.new(StandardError) }

        before do
          fetch_counter = 0

          allow(cleaner).to receive(:fetch_batch).and_wrap_original do |m, *args|
            raise dummy_error if fetch_counter == 1

            fetch_counter += 1
            m.call(*args)
          end
        end
      end

      shared_examples_for 'handling dry run mode' do
        context 'when on dry run (which is default)' do
          it 'logs orphan objects to delete but does not delete them' do
            run

            expect_start_log_message
            expect_first_page_loading_log_message
            expect_page_loading_via_marker_log_message(times: 3)
            expect_delete_log_message(orphan_final_object_1)
            expect_delete_log_message(orphan_final_object_2)
            expect_no_delete_log_message(orphan_non_final_object)
            expect_no_delete_log_message(non_orphan_final_object_1)
            expect_no_delete_log_message(non_orphan_final_object_2)
            expect_done_log_message

            expect_object_to_exist(orphan_final_object_1)
            expect_object_to_exist(orphan_final_object_2)
            expect_object_to_exist(orphan_non_final_object)
            expect_object_to_exist(non_orphan_final_object_1)
            expect_object_to_exist(non_orphan_final_object_2)
          end

          context 'when interrupted in the middle of processing pages' do
            include_context 'when resuming from marker'

            it 'resumes from last known page marker on the next run' do
              expect { cleaner.run! }.to raise_error(dummy_error)
              saved_marker = fetch_saved_marker

              new_cleaner = described_class.new(
                provider: specified_provider,
                force_restart: false,
                dry_run: true
              )

              new_cleaner.run!

              expect_resuming_from_marker_log_message(saved_marker)

              # Given we can't guarantee the order of the objects because
              # of random path generation, we can't tell which page they will
              # fall in, so we will just ensure that they
              # were all logged in the end.
              expect_delete_log_message(orphan_final_object_1)
              expect_delete_log_message(orphan_final_object_2)

              # Ensure that they were not deleted because this is just dry run.
              expect_object_to_exist(orphan_final_object_1)
              expect_object_to_exist(orphan_final_object_2)
            end

            context 'and force_restart is true' do
              it 'starts from the first page on the next run' do
                expect { cleaner.run! }.to raise_error(dummy_error)

                new_cleaner = described_class.new(
                  provider: specified_provider,
                  force_restart: true,
                  dry_run: true
                )

                new_cleaner.run!

                expect_no_resuming_from_marker_log_message

                # Ensure that they were not deleted because this is just dry run.
                expect_object_to_exist(orphan_final_object_1)
                expect_object_to_exist(orphan_final_object_2)
              end
            end
          end
        end

        context 'when dry run is set to false' do
          let(:dry_run) { false }

          it 'logs orphan objects to delete and deletes them' do
            expect_object_to_exist(orphan_final_object_1)
            expect_object_to_exist(orphan_final_object_2)

            run

            expect_start_log_message
            expect_first_page_loading_log_message
            expect_page_loading_via_marker_log_message(times: 3)
            expect_delete_log_message(orphan_final_object_1)
            expect_delete_log_message(orphan_final_object_2)
            expect_no_delete_log_message(orphan_non_final_object)
            expect_no_delete_log_message(non_orphan_final_object_1)
            expect_no_delete_log_message(non_orphan_final_object_2)
            expect_done_log_message

            expect_object_to_be_deleted(orphan_final_object_1)
            expect_object_to_be_deleted(orphan_final_object_2)
            expect_object_to_exist(orphan_non_final_object)
            expect_object_to_exist(non_orphan_final_object_1)
            expect_object_to_exist(non_orphan_final_object_2)
          end

          context 'when interrupted in the middle of processing pages' do
            include_context 'when resuming from marker'

            it 'resumes from last known page marker on the next run' do
              expect { cleaner.run! }.to raise_error(dummy_error)
              saved_marker = fetch_saved_marker

              new_cleaner = described_class.new(
                provider: specified_provider,
                force_restart: false,
                dry_run: false
              )

              new_cleaner.run!

              expect_resuming_from_marker_log_message(saved_marker)

              # Given we can't guarantee the order of the objects because
              # of random path generation, we can't tell which page they will
              # fall in, so we will just ensure that they
              # were all logged in the end.
              expect_delete_log_message(orphan_final_object_1)
              expect_delete_log_message(orphan_final_object_2)

              # Ensure that they were deleted because this is not dry run.
              expect_object_to_be_deleted(orphan_final_object_1)
              expect_object_to_be_deleted(orphan_final_object_2)
            end

            context 'and force_restart is true' do
              it 'starts from the first page on the next run' do
                expect { cleaner.run! }.to raise_error(dummy_error)

                new_cleaner = described_class.new(
                  provider: specified_provider,
                  force_restart: true,
                  dry_run: false
                )

                new_cleaner.run!

                expect_no_resuming_from_marker_log_message

                # Ensure that they were deleted because this is not a dry run.
                expect_object_to_be_deleted(orphan_final_object_1)
                expect_object_to_be_deleted(orphan_final_object_2)
              end
            end
          end
        end
      end

      context 'when not configured to use bucket_prefix' do
        let(:remote_directory) { 'artifacts' }
        let(:bucket_prefix) { nil }

        it_behaves_like 'handling dry run mode'
      end

      context 'when configured to use bucket_prefix' do
        let(:remote_directory) { 'main-bucket' }
        let(:bucket_prefix) { 'my/artifacts' }

        it_behaves_like 'handling dry run mode'
      end
    end

    context 'when defaulting to provider in the object store configuration' do
      let(:specified_provider) { nil }

      it_behaves_like 'cleaning up orphan final job artifact objects'
    end

    context 'when provider is specified' do
      context 'and provider is supported' do
        let(:specified_provider) { 'aws' }

        it_behaves_like 'cleaning up orphan final job artifact objects'
      end

      context 'and provider is not supported' do
        let(:specified_provider) { 'somethingelse' }

        it 'raises an error' do
          expect { run }.to raise_error(described_class::UnsupportedProviderError)
        end
      end
    end
  end
end
