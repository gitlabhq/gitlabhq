# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Framework::AttachmentDownloads, feature_category: :importers do
  let(:tmp_dir) { File.join(Dir.tmpdir, 'attachment_downloads_spec') }
  let(:uuid_regex) { /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/ }

  let(:host_class) do
    temp_dir = tmp_dir

    Class.new do
      include ::Gitlab::ImportExport::CommandLineUtil
      include ::BulkImports::FileDownloads::FilenameFetch
      include ::Import::Framework::AttachmentDownloads

      attr_reader :filename

      define_method(:attachments_temp_dir) { temp_dir }

      def initialize(file_url)
        @filename = build_filename(file_url)
      end
    end
  end

  let(:file_url) { 'https://example.com/avatar.png' }

  subject(:downloader) { host_class.new(file_url) }

  describe 'abstract methods' do
    let(:bare_host) { Class.new { include ::Import::Framework::AttachmentDownloads }.new }

    it 'requires attachments_temp_dir to be implemented' do
      expect { bare_host.send(:attachments_temp_dir) }.to raise_error(Gitlab::AbstractMethodError)
    end

    it 'requires filename to be implemented' do
      expect { bare_host.send(:filename) }.to raise_error(Gitlab::AbstractMethodError)
    end
  end

  describe '#sanitize_filename' do
    {
      'file@#$%name-2.pdf' => 'file____name-2.pdf',
      'file with spaces.txt' => 'file_with_spaces.txt',
      'C++.Coding.Style.Guide.pdf' => 'C__.Coding.Style.Guide.pdf',
      '..hidden-file.txt' => 'hidden-file.txt',
      '@#$%' => 'attachment',
      '____' => 'attachment',
      '' => 'attachment'
    }.each do |input, expected|
      it "sanitizes #{input.inspect} to #{expected.inspect}" do
        expect(downloader.send(:sanitize_filename, input)).to eq(expected)
      end
    end
  end

  describe '#build_filename' do
    context 'when the URL contains encoded special characters' do
      let(:file_url) { 'https://example.com/C%2B%2B.Coding.Style.Guide.pdf' }

      it 'decodes and sanitizes the filename' do
        expect(downloader.filename).to eq('C__.Coding.Style.Guide.pdf')
      end
    end

    context 'when the URL contains encoded path separators' do
      let(:file_url) { 'https://example.com/file%2Fwith%2Fslashes.txt' }

      it 'sanitizes the path separators' do
        expect(downloader.filename).to eq('file_with_slashes.txt')
      end
    end

    context 'when the filename is malicious' do
      let(:file_url) { 'https://example.com/ava%2F..%2Ftar.png' }

      it 'raises a path traversal error' do
        expect { downloader }.to raise_error(
          Gitlab::PathTraversal::PathTraversalAttackError,
          'Invalid path'
        )
      end
    end
  end

  describe '#filepath' do
    it 'builds a path under the temp dir within a UUID subdirectory' do
      filepath = downloader.send(:filepath)

      dir = File.dirname(filepath)
      expect(File.dirname(dir)).to eq(tmp_dir)
      expect(File.basename(dir)).to match(uuid_regex)
      expect(File.basename(filepath)).to eq(downloader.filename)
    end

    it 'creates the directory' do
      filepath = downloader.send(:filepath)

      expect(Dir.exist?(File.dirname(filepath))).to be(true)
    end

    it 'memoises the path' do
      first_call = downloader.send(:filepath)

      expect(downloader.send(:filepath)).to be(first_call)
    end
  end

  describe '#add_extension_to_file_path' do
    it 'appends the extension of the given filename to the filepath' do
      original = downloader.send(:filepath)

      result = downloader.send(:add_extension_to_file_path, 'video.mp4')

      expect(result).to eq("#{original}.mp4")
      expect(downloader.send(:filepath)).to eq("#{original}.mp4")
    end
  end
end
