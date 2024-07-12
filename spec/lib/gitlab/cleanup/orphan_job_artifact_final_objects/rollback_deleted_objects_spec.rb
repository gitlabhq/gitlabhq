# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cleanup::OrphanJobArtifactFinalObjects::RollbackDeletedObjects, :orphan_final_artifacts_cleanup, :clean_gitlab_redis_shared_state, feature_category: :job_artifacts do
  describe '#run!' do
    let!(:fog_connection) do
      stub_object_storage_uploader(
        config: Gitlab.config.artifacts.object_store,
        uploader: JobArtifactUploader,
        direct_upload: true
      )
    end

    let(:remote_directory) { 'artifacts' }
    let(:bucket_prefix) { nil }

    let(:processor) do
      described_class.new(
        force_restart: force_restart,
        filename: deleted_list_filename
      )
    end

    let(:deleted_list_filename) { described_class::DEFAULT_DELETED_LIST_FILENAME }
    let(:force_restart) { false }

    let(:deleted_object_1) { build_dummy_deleted_final_object }
    let(:deleted_object_2) { build_dummy_deleted_final_object }
    let(:deleted_object_3) { build_dummy_deleted_final_object }

    before do
      allow(Gitlab::AppLogger).to receive(:info)

      File.open(deleted_list_filename, 'a') do |file|
        file.puts([deleted_object_1.key, deleted_object_1.content_length, deleted_object_1.generation].join(','))
        file.puts([deleted_object_2.key, deleted_object_2.content_length, deleted_object_2.generation].join(','))
        file.puts([deleted_object_3.key, deleted_object_3.content_length, deleted_object_3.generation].join(','))
      end
    end

    after do
      File.delete(deleted_list_filename) if File.file?(deleted_list_filename)
    end

    subject(:run) { processor.run! }

    context 'when configured object store provider is Google' do
      before do
        # Fog would still load the AWS provider implementation so we just
        # want to fake it here to avoid the UnsupportedProviderError.
        allow(Gitlab.config.artifacts.object_store.connection).to receive(:provider).and_return('Google')
      end

      it 'rolls back deleted objects to the specified generation' do
        # These dummy objects match the entries from the CSV.
        # We want to ensure that the values from the CSV are properly used, specially
        # the generation value.
        [deleted_object_1, deleted_object_2, deleted_object_3].each do |object|
          expect(processor)
            .to receive(:new_fog_file)
            .with(object.key, object.generation)
            .and_return(object)

          # Given Fog doesn't have mock implementation for Google provider, we can only
          # check that the copy method is properly called with the correct parameters.
          expect_to_copy_with_source_generation(object)
        end

        run

        expect_processing_list_log_message(deleted_list_filename)
        expect_rolled_back_deleted_object_log_message(deleted_object_1)
        expect_rolled_back_deleted_object_log_message(deleted_object_2)
        expect_rolled_back_deleted_object_log_message(deleted_object_3)
        expect_done_rolling_back_deletion_log_message(deleted_list_filename)
      end

      context 'when interrupted in the middle of processing entries' do
        let(:dummy_error) { Class.new(StandardError) }

        before do
          loop_counter = 0

          allow(processor).to receive(:build_fog_file).and_wrap_original do |m, *args|
            raise dummy_error if loop_counter == 1

            loop_counter += 1
            m.call(*args)
          end
        end

        it 'resumes from last known cursor position on the next run' do
          expect(processor)
            .to receive(:new_fog_file)
            .with(deleted_object_1.key, deleted_object_1.generation)
            .and_return(deleted_object_1)

          expect_to_copy_with_source_generation(deleted_object_1)

          expect { processor.run! }.to raise_error(dummy_error)

          expect_rolled_back_deleted_object_log_message(deleted_object_1)

          saved_cursor_position = fetch_saved_cursor_position(deleted_list_filename)

          new_processor = described_class.new(
            force_restart: false,
            filename: deleted_list_filename
          )

          # We expect to resume and process the last 2 entries in the CSV
          [deleted_object_2, deleted_object_3].each do |object|
            expect(new_processor)
              .to receive(:new_fog_file)
              .with(object.key, object.generation)
              .and_return(object)

            expect_to_copy_with_source_generation(object)
          end

          new_processor.run!

          expect_resuming_from_cursor_position_log_message(deleted_list_filename, saved_cursor_position)
          expect_rolled_back_deleted_object_log_message(deleted_object_2)
          expect_rolled_back_deleted_object_log_message(deleted_object_3)
          expect_done_rolling_back_deletion_log_message(deleted_list_filename)
        end

        context 'and force_restart is true' do
          it 'starts from the first entry on the next run' do
            expect(processor)
              .to receive(:new_fog_file)
              .with(deleted_object_1.key, deleted_object_1.generation)
              .and_return(deleted_object_1)

            expect_to_copy_with_source_generation(deleted_object_1)

            expect { processor.run! }.to raise_error(dummy_error)

            new_processor = described_class.new(
              force_restart: true,
              filename: deleted_list_filename
            )

            # We expect to start from top and process all 3 entries in the CSV
            [deleted_object_1, deleted_object_2, deleted_object_3].each do |object|
              expect(new_processor)
                .to receive(:new_fog_file)
                .with(object.key, object.generation)
                .and_return(object)

              expect_to_copy_with_source_generation(object)
            end

            new_processor.run!

            expect_no_resuming_from_cursor_position_log_message
            expect_rolled_back_deleted_object_log_message(deleted_object_1, times: 2)
            expect_rolled_back_deleted_object_log_message(deleted_object_2)
            expect_rolled_back_deleted_object_log_message(deleted_object_3)
            expect_done_rolling_back_deletion_log_message(deleted_list_filename)
          end
        end
      end

      context 'when the list file of deleted objects does not exist' do
        before do
          File.delete(deleted_list_filename)
        end

        it 'raises an error' do
          expect { run }.to raise_error(/No such file.*#{Regexp.quote(deleted_list_filename)}/)
        end
      end

      context 'when one of the deleted objects already has a live version on storage' do
        it 'does not fail but skips rolling back the object' do
          [deleted_object_1, deleted_object_2, deleted_object_3].each do |object|
            expect(processor)
              .to receive(:new_fog_file)
              .with(object.key, object.generation)
              .and_return(object)
          end

          expect(deleted_object_1)
            .to receive(:copy)
            .and_raise(
              Google::Apis::ClientError,
              'conditionNotMet: At least one of the pre-conditions you specified did not hold'
            )

          expect_to_copy_with_source_generation(deleted_object_2)
          expect_to_copy_with_source_generation(deleted_object_3)

          run

          expect_skipping_object_with_live_version_log_message(deleted_object_1)
          expect_rolled_back_deleted_object_log_message(deleted_object_2)
          expect_rolled_back_deleted_object_log_message(deleted_object_3)
          expect_done_rolling_back_deletion_log_message(deleted_list_filename)
        end
      end
    end

    context 'when configured object store provider is not Google' do
      it 'raises an error' do
        expect { run }.to raise_error(described_class::UnsupportedProviderError)
      end
    end
  end
end
