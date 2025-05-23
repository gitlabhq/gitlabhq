# frozen_string_literal: true

# Requires let variables:
# - :bucket_name
# - :model_class
# - :stub_object_storage_uploader_for_cleaner
# - :tracked_file_path
# - :unknown_path_format_file_path
# - :untracked_valid_file_path
RSpec.shared_examples 'remote object storage cleaner' do
  # Change to Logger.new($stdout) if you want to see the output while debugging tests
  let(:logger) { Logger.new(nil) }

  subject(:cleaner) { described_class.new(logger: logger) }

  describe '.storage_location_identifier' do
    it 'returns the correct bucket name' do
      expect(described_class.new.send(:storage_location_identifier)).to eq(bucket_name.to_sym)
    end
  end

  describe '.model_class' do
    it 'returns the correct model class' do
      expect(described_class.new.model_class).to eq(model_class)
    end
  end

  context 'when object_storage is not enabled' do
    before do
      allow(cleaner).to receive(:config).and_return(GitlabSettings::Options.build({ enabled: false }))
    end

    it 'does not connect to any storage' do
      expect(logger).to receive(:warn).with(/Object storage not enabled/)
      expect(::Fog::Storage).not_to receive(:new)

      cleaner.run!
    end
  end

  context 'when object_storage is enabled' do
    let(:lost_and_found_dir) { 'lost_and_found' }
    let(:tracked_file) { instance_double(Fog::AWS::Storage::File, key: tracked_file_path) }
    let(:untracked_file) { instance_double(Fog::AWS::Storage::File, key: untracked_valid_file_path) }
    let(:lost_and_found_file) { instance_double(Fog::AWS::Storage::File, key: "#{lost_and_found_dir}/already_moved") }
    let(:unknown_path_format_file) { instance_double(Fog::AWS::Storage::File, key: unknown_path_format_file_path) }
    let(:remote_files) { [tracked_file, untracked_file, lost_and_found_file, unknown_path_format_file] }

    before do
      stub_object_storage_uploader_for_cleaner

      # Stub object storage call
      remote_directory = Struct.new(:files).new(files: remote_files)
      allow(cleaner).to receive(:remote_directory).and_return(remote_directory)
    end

    context 'when dry_run is set to false' do
      subject(:run) { cleaner.run!(dry_run: false) }

      it 'only moves files that are not tracked in the database and have a known path format' do
        # Move
        expect(untracked_file).to receive(:copy)
        expect(untracked_file).to receive(:destroy)

        # Don't move
        expect(tracked_file).not_to receive(:copy)
        expect(tracked_file).not_to receive(:destroy)
        expect(lost_and_found_file).not_to receive(:copy)
        expect(lost_and_found_file).not_to receive(:destroy)
        expect(unknown_path_format_file).not_to receive(:copy)
        expect(unknown_path_format_file).not_to receive(:destroy)

        run
      end

      context 'when delete is set to true' do
        subject(:run) { cleaner.run!(dry_run: false, delete: true) }

        it 'permanently deletes untracked files instead of moving them' do
          # Destroyed without being copied
          expect(untracked_file).not_to receive(:copy)
          expect(untracked_file).to receive(:destroy)

          # Not destroyed nor copied
          expect(tracked_file).not_to receive(:copy)
          expect(tracked_file).not_to receive(:destroy)
          expect(lost_and_found_file).not_to receive(:copy)
          expect(lost_and_found_file).not_to receive(:destroy)
          expect(unknown_path_format_file).not_to receive(:copy)
          expect(unknown_path_format_file).not_to receive(:destroy)

          run
        end
      end
    end

    context 'when dry_run is set to true' do
      subject(:run) { cleaner.run!(dry_run: true) }

      it 'does not move or delete any files' do
        # No files should be touched in dry run mode
        expect(tracked_file).not_to receive(:copy)
        expect(tracked_file).not_to receive(:destroy)
        expect(untracked_file).not_to receive(:copy)
        expect(untracked_file).not_to receive(:destroy)
        expect(lost_and_found_file).not_to receive(:copy)
        expect(lost_and_found_file).not_to receive(:destroy)
        expect(unknown_path_format_file).not_to receive(:copy)
        expect(unknown_path_format_file).not_to receive(:destroy)

        run
      end
    end

    context 'when a bucket prefix is configured' do
      before do
        allow(cleaner).to receive(:bucket_prefix).and_return('test-prefix')
      end

      it 'does not connect to any storage and logs error' do
        expect(logger).to receive(:error)
        expect(::Fog::Storage).not_to receive(:new)

        cleaner.run!
      end
    end
  end
end
