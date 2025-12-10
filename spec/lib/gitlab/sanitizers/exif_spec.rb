# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Sanitizers::Exif do
  let(:sanitizer) { described_class.new }
  let(:mime_type) { 'image/jpeg' }

  before do
    allow(Gitlab::Utils::MimeType).to receive(:from_string).and_return(mime_type)
  end

  describe '#batch_clean' do
    context 'with image uploads' do
      let_it_be(:upload1) { create(:upload, :with_file, :issuable_upload) }
      let_it_be(:upload2) { create(:upload, :with_file, :personal_snippet_upload) }
      let_it_be(:upload3) { create(:upload, :with_file, created_at: 3.days.ago) }

      it 'processes all uploads if range ID is not set' do
        expect(sanitizer).to receive(:clean).exactly(3).times

        sanitizer.batch_clean
      end

      it 'processes only uploads in the selected range' do
        expect(sanitizer).to receive(:clean).once

        sanitizer.batch_clean(start_id: upload1.id, stop_id: upload1.id)
      end

      it 'processes only uploads for the selected uploader' do
        expect(sanitizer).to receive(:clean).once

        sanitizer.batch_clean(uploader: 'PersonalFileUploader')
      end

      it 'processes only uploads created since specified date' do
        expect(sanitizer).to receive(:clean).twice

        sanitizer.batch_clean(since: 2.days.ago)
      end

      it 'pauses if sleep_time is set' do
        expect(sanitizer).to receive(:sleep).exactly(3).times.with(1.second)
        expect(sanitizer).to receive(:clean).exactly(3).times

        sanitizer.batch_clean(sleep_time: 1)
      end
    end

    it 'filters only jpg/tiff images by filename' do
      create(:upload, path: 'filename.jpg')
      create(:upload, path: 'filename.jpeg')
      create(:upload, path: 'filename.JPG')
      create(:upload, path: 'filename.tiff')
      create(:upload, path: 'filename.TIFF')
      create(:upload, path: 'filename.png')
      create(:upload, path: 'filename.txt')

      expect(sanitizer).to receive(:clean).exactly(5).times

      sanitizer.batch_clean
    end
  end

  describe '#clean' do
    let(:uploader) { create(:upload, :with_file, :issuable_upload).retrieve_uploader }
    let(:dry_run) { false }

    subject { sanitizer.clean(uploader, dry_run: dry_run) }

    context "no dry run" do
      it "removes exif from the image" do
        uploader.store!(fixture_file_upload('spec/fixtures/rails_sample.jpg'))

        original_upload = uploader.upload
        expect(sanitizer).to receive(:exec_remove_exif!).once.and_call_original
        expect(uploader).to receive(:store!).and_call_original
        expect(Gitlab::Popen).to receive(:popen).with(["exiftool", "-IPTC=", "-XMP=", kind_of(String)]) do |args|
          File.write("#{args.last}_original", "foo") if args.last.start_with?(Dir.tmpdir)

          [args, 0]
        end
        expect(Gitlab::Popen).to receive(:popen).with(["exiftool", "-all=", "-tagsFromFile", "@", *Gitlab::Sanitizers::Exif::EXCLUDE_PARAMS, kind_of(String)]) do |args|
          File.write("#{args.last}_original", "foo") if args.last.start_with?(Dir.tmpdir)

          [args, 0]
        end

        subject

        expect(uploader.upload.id).not_to eq(original_upload.id)
        expect(uploader.upload.path).to eq(original_upload.path)
      end

      it "raises an error if the exiftool fails with an error" do
        expect(Gitlab::Popen).to receive(:popen).and_return(["error_message", 1])

        expect { subject }.to raise_exception(RuntimeError, "exiftool return code is 1: error_message")
      end

      context 'for files that do not have the correct MIME type' do
        let(:mime_type) { 'text/plain' }

        it 'cleans only jpg/tiff images with the correct mime types' do
          expect { subject }.to raise_error(RuntimeError, %r{File type text/plain not supported})
        end
      end
    end

    context "dry run" do
      let(:dry_run) { true }

      it "doesn't change the image" do
        expect(sanitizer).not_to receive(:exec_remove_exif!)
        expect(uploader).not_to receive(:store!)

        subject
      end
    end
  end

  describe '#clean_existing_path' do
    let(:dry_run) { false }

    let(:tmp_file) { Tempfile.new("rails_sample.jpg") }

    subject { sanitizer.clean_existing_path(tmp_file.path, dry_run: dry_run) }

    context "no dry run" do
      let(:file_content) { fixture_file_upload('spec/fixtures/rails_sample.jpg') }

      before do
        File.open(tmp_file.path, "w+b") { |f| f.write file_content }
      end

      it "removes exif from the image" do
        expect(sanitizer).to receive(:exec_remove_exif!).once.and_call_original
        expect(Gitlab::Popen).to receive(:popen).with(["exiftool", "-IPTC=", "-XMP=", kind_of(String)]) do |args|
          File.write("#{args.last}_original", "foo") if args.last.start_with?(Dir.tmpdir)

          [args, 0]
        end

        expect(Gitlab::Popen).to receive(:popen).with(["exiftool", "-all=", "-tagsFromFile", "@", *Gitlab::Sanitizers::Exif::EXCLUDE_PARAMS, kind_of(String)]) do |args|
          File.write("#{args.last}_original", "foo") if args.last.start_with?(Dir.tmpdir)

          [args, 0]
        end

        subject
      end

      it "raises an error if the exiftool fails with an error" do
        expect(Gitlab::Popen).to receive(:popen).and_return(["error_message", 1])

        expect { subject }.to raise_exception(RuntimeError, "exiftool return code is 1: error_message")
      end

      context 'for files that do not have the correct MIME type from file' do
        let(:mime_type) { 'text/plain' }

        it 'cleans only jpg/tiff images with the correct mime types' do
          expect { subject }.to raise_error(RuntimeError, %r{File type text/plain not supported})
        end
      end

      context 'skip_unallowed_types is false' do
        context 'for files that do not have the correct MIME type from input content' do
          let(:mime_type) { 'text/plain' }

          it 'raises an error if not jpg/tiff images with the correct mime types' do
            expect do
              sanitizer.clean_existing_path(tmp_file.path, content: file_content)
            end.to raise_error(RuntimeError, %r{File type text/plain not supported})
          end
        end

        context 'for files that do not have the correct MIME type from input content' do
          let(:mime_type) { 'text/plain' }

          it 'raises an error if not jpg/tiff images with the correct mime types' do
            expect do
              sanitizer.clean_existing_path(tmp_file.path, content: file_content)
            end.to raise_error(RuntimeError, %r{File type text/plain not supported})
          end
        end
      end

      context 'skip_unallowed_types is true' do
        context 'for files that do not have the correct MIME type from input content' do
          let(:mime_type) { 'text/plain' }

          it 'cleans only jpg/tiff images with the correct mime types' do
            expect do
              sanitizer.clean_existing_path(tmp_file.path, content: file_content, skip_unallowed_types: true)
            end.not_to raise_error
          end
        end

        context 'for files that do not have the correct MIME type from input content' do
          let(:mime_type) { 'text/plain' }

          it 'cleans only jpg/tiff images with the correct mime types' do
            expect do
              sanitizer.clean_existing_path(tmp_file.path, content: file_content, skip_unallowed_types: true)
            end.not_to raise_error
          end
        end
      end
    end

    context "dry run" do
      let(:dry_run) { true }

      it "doesn't change the image" do
        expect(sanitizer).not_to receive(:exec_remove_exif!)

        subject
      end
    end
  end
end
