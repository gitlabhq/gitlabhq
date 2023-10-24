# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SafeZip::Extract do
  let(:target_path) { Dir.mktmpdir('safe-zip') }
  let(:directories) { %w[public] }
  let(:files) { %w[public/index.html] }
  let(:object) { described_class.new(archive) }
  let(:archive) { Rails.root.join('spec', 'fixtures', 'safe_zip', archive_name) }

  after do
    FileUtils.remove_entry_secure(target_path)
  end

  describe '#extract' do
    subject { object.extract(directories: directories, files: files, to: target_path) }

    shared_examples 'extracts archive' do
      context 'when specifying directories' do
        subject { object.extract(directories: directories, to: target_path) }

        it 'does extract archive' do
          subject

          expect(File.exist?(File.join(target_path, 'public', 'index.html'))).to eq(true)
          expect(File.exist?(File.join(target_path, 'public', 'assets', 'image.png'))).to eq(true)
          expect(File.exist?(File.join(target_path, 'source'))).to eq(false)
        end
      end

      context 'when specifying files' do
        subject { object.extract(files: files, to: target_path) }

        it 'does extract archive' do
          subject

          expect(File.exist?(File.join(target_path, 'public', 'index.html'))).to eq(true)
          expect(File.exist?(File.join(target_path, 'public', 'assets', 'image.png'))).to eq(false)
        end
      end
    end

    shared_examples 'fails to extract archive' do
      it 'does not extract archive' do
        expect { subject }.to raise_error(SafeZip::Extract::Error, including(error_message))
      end
    end

    %w[valid-simple.zip valid-symlinks-first.zip valid-non-writeable.zip].each do |name|
      context "when using #{name} archive" do
        let(:archive_name) { name }

        it_behaves_like 'extracts archive'
      end
    end

    context 'when zip files are invalid' do
      using RSpec::Parameterized::TableSyntax

      where(:name, :message) do
        'invalid-symlink-does-not-exist.zip' | 'does not exist'
        'invalid-symlinks-outside.zip' | 'Symlink cannot be created'
        'invalid-unexpected-large.zip' | 'larger when inflated'
      end

      with_them do
        let(:archive_name) { name }
        let(:error_message) { message }

        it_behaves_like 'fails to extract archive'
      end
    end

    context 'when no matching directories are found' do
      let(:archive_name) { 'valid-simple.zip' }
      let(:directories) { %w[non/existing] }
      let(:error_message) { 'No entries extracted' }

      subject { object.extract(directories: directories, to: target_path) }

      it_behaves_like 'fails to extract archive'
    end

    context 'when no matching files are found' do
      let(:archive_name) { 'valid-simple.zip' }
      let(:files) { %w[non/existing] }
      let(:error_message) { 'No entries extracted' }

      subject { object.extract(files: files, to: target_path) }

      it_behaves_like 'fails to extract archive'
    end
  end
end
