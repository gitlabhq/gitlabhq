# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cleanup::OrphanJobArtifactFinalObjects::GenerateList, :orphan_final_artifacts_cleanup, :clean_gitlab_redis_shared_state, feature_category: :job_artifacts do
  describe '#run!' do
    let(:generator) do
      described_class.new(
        provider: specified_provider,
        force_restart: force_restart,
        filename: filename
      )
    end

    let(:filename) { 'orphan_objects.csv' }
    let(:force_restart) { false }
    let(:remote_directory) { 'artifacts' }
    let(:bucket_prefix) { nil }

    subject(:run) { generator.run! }

    before do
      stub_const('Gitlab::Cleanup::OrphanJobArtifactFinalObjects::Paginators::BasePaginator::BATCH_SIZE', 2)

      Gitlab.config.artifacts.object_store.tap do |config|
        config[:remote_directory] = remote_directory
        config[:bucket_prefix] = bucket_prefix
      end

      allow(Gitlab::AppLogger).to receive(:info)
    end

    after do
      File.delete(filename) if File.file?(filename)
    end

    shared_examples_for 'handling supported provider' do
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

          allow(generator).to receive(:fetch_batch).and_wrap_original do |m, *args|
            raise dummy_error if fetch_counter == 1

            fetch_counter += 1
            m.call(*args)
          end
        end
      end

      shared_examples_for 'listing orphan final job artifact objects' do
        it 'lists paths and sizes of all orphan objects to the generated file' do
          run

          expect_start_log_message
          expect_first_page_loading_log_message
          expect_found_orphan_artifact_object_log_message(orphan_final_object_1)
          expect_found_orphan_artifact_object_log_message(orphan_final_object_2)
          expect_no_found_orphan_artifact_object_log_message(orphan_non_final_object)
          expect_no_found_orphan_artifact_object_log_message(non_orphan_final_object_1)
          expect_no_found_orphan_artifact_object_log_message(non_orphan_final_object_2)
          expect_done_log_message(filename)

          expect_orphans_list_to_contain_exactly(filename, [
            orphan_final_object_1,
            orphan_final_object_2
          ])
        end

        context 'when interrupted in the middle of processing pages' do
          include_context 'when resuming from marker'

          let!(:orphan_final_object_3) { create_fog_file }
          let!(:orphan_final_object_4) { create_fog_file }
          let!(:orphan_final_object_5) { create_fog_file }

          before do
            # To better test that the file still contains the orphan objects
            # from previous execution, we want to only have orphan final objects
            # in the storage for now. This is because we can't guarantee load order
            # but we want to be sure that there is an orphan object loaded in the first
            # execution. Now, we will only have 5 objects in the storage, and they
            # are orphan_final_object_1 to 5.
            # rubocop:disable Rails/SaveBang -- The destroy method here is not ActiveRecord
            orphan_non_final_object.destroy
            non_orphan_final_object_1.destroy
            non_orphan_final_object_2.destroy
            # rubocop:enable Rails/SaveBang
          end

          it 'resumes from last known page marker on the next run' do
            expect { generator.run! }.to raise_error(dummy_error)
            saved_marker = fetch_saved_marker

            new_generator = described_class.new(
              provider: specified_provider,
              force_restart: false,
              filename: filename
            )

            new_generator.run!

            expect_resuming_from_marker_log_message(saved_marker)

            # Given we can't guarantee the order of the objects because
            # of random path generation, we can't tell which page they will
            # fall in, so we will just ensure that they
            # were all logged in the end.
            expect_found_orphan_artifact_object_log_message(orphan_final_object_1)
            expect_found_orphan_artifact_object_log_message(orphan_final_object_2)
            expect_found_orphan_artifact_object_log_message(orphan_final_object_3)
            expect_found_orphan_artifact_object_log_message(orphan_final_object_4)
            expect_found_orphan_artifact_object_log_message(orphan_final_object_5)

            expect_orphans_list_to_contain_exactly(filename, [
              orphan_final_object_1,
              orphan_final_object_2,
              orphan_final_object_3,
              orphan_final_object_4,
              orphan_final_object_5
            ])
          end

          context 'and force_restart is true' do
            it 'starts from the first page on the next run' do
              expect { generator.run! }.to raise_error(dummy_error)

              # Given the batch size is 2, and we only have 5 objects right now in the storage
              # and they are all orphans, we expect the file to have 2 entries.
              expect_orphans_list_to_have_number_of_entries(2)

              # Before we re-run, we want to delete some of the objects so we can
              # test that the file indeed was truncated first before adding in new entries.
              # Let's delete 4 objects.
              # rubocop:disable Rails/SaveBang -- The destroy method here is not ActiveRecord
              orphan_final_object_2.destroy
              orphan_final_object_3.destroy
              orphan_final_object_4.destroy
              orphan_final_object_5.destroy
              # rubocop:enable Rails/SaveBang

              new_generator = described_class.new(
                provider: specified_provider,
                force_restart: true,
                filename: filename
              )

              new_generator.run!

              expect_no_resuming_from_marker_log_message

              # Now we should have only 1 entry. Given the first restart, the file
              # should have been truncated first, before new entries are added.
              expect_orphans_list_to_have_number_of_entries(1)
            end
          end
        end
      end

      context 'when not configured to use bucket_prefix' do
        let(:remote_directory) { 'artifacts' }
        let(:bucket_prefix) { nil }

        it_behaves_like 'listing orphan final job artifact objects'
      end

      context 'when configured to use bucket_prefix' do
        let(:remote_directory) { 'main-bucket' }
        let(:bucket_prefix) { 'my/artifacts' }

        it_behaves_like 'listing orphan final job artifact objects'
      end
    end

    context 'when defaulting to provider in the object store configuration' do
      let(:specified_provider) { nil }

      it_behaves_like 'handling supported provider'

      context 'and the configured provider is not supported' do
        before do
          allow(Gitlab.config.artifacts.object_store.connection).to receive(:provider).and_return('somethingelse')
        end

        it 'raises an error' do
          expect { run }.to raise_error(
            described_class::UnsupportedProviderError,
            /The provider found in the object storage configuration is unsupported/
          )
        end
      end
    end

    context 'when provider is specified' do
      context 'and provider is supported' do
        let(:specified_provider) { 'aws' }

        it_behaves_like 'handling supported provider'
      end

      context 'and provider is not supported' do
        let(:specified_provider) { 'somethingelse' }

        it 'raises an error' do
          expect { run }.to raise_error(
            described_class::UnsupportedProviderError,
            /The provided provider is unsupported/
          )
        end
      end
    end
  end
end
