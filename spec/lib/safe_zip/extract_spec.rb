# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SafeZip::Extract do
  let(:target_path) { Dir.mktmpdir('safe-zip') }
  let(:directories) { %w(public) }
  let(:object) { described_class.new(archive) }
  let(:archive) { Rails.root.join('spec', 'fixtures', 'safe_zip', archive_name) }

  after do
    FileUtils.remove_entry_secure(target_path)
  end

  describe '#extract' do
    subject { object.extract(directories: directories, to: target_path) }

    shared_examples 'extracts archive' do
      it 'does extract archive' do
        subject

        expect(File.exist?(File.join(target_path, 'public', 'index.html'))).to eq(true)
        expect(File.exist?(File.join(target_path, 'source'))).to eq(false)
      end
    end

    shared_examples 'fails to extract archive' do
      it 'does not extract archive' do
        expect { subject }.to raise_error(SafeZip::Extract::Error)
      end
    end

    %w(valid-simple.zip valid-symlinks-first.zip valid-non-writeable.zip).each do |name|
      context "when using #{name} archive" do
        let(:archive_name) { name }

        it_behaves_like 'extracts archive'
      end
    end

    %w(invalid-symlink-does-not-exist.zip invalid-symlinks-outside.zip).each do |name|
      context "when using #{name} archive" do
        let(:archive_name) { name }

        it_behaves_like 'fails to extract archive'
      end
    end

    context 'when no matching directories are found' do
      let(:archive_name) { 'valid-simple.zip' }
      let(:directories) { %w(non/existing) }

      it_behaves_like 'fails to extract archive'
    end
  end
end
