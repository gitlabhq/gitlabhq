# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::ArchiveExtractionService, feature_category: :importers do
  let_it_be(:tmpdir) { Dir.mktmpdir }
  let_it_be(:filename) { 'symlink_export.tar' }
  let_it_be(:filepath) { File.join(tmpdir, filename) }

  before do
    FileUtils.copy_file(File.join('spec', 'fixtures', filename), filepath)
  end

  after(:all) do
    FileUtils.remove_entry(tmpdir)
  end

  subject(:service) { described_class.new(tmpdir: tmpdir, filename: filename) }

  describe '#execute' do
    it 'extracts files from archive and removes symlinks' do
      file = File.join(tmpdir, 'project.json')
      folder = File.join(tmpdir, 'uploads')
      symlink = File.join(tmpdir, 'uploads', 'link.gitignore')

      expect(service).to receive(:untar_xf).with(archive: filepath, dir: tmpdir).and_call_original

      service.execute

      expect(File.exist?(file)).to eq(true)
      expect(Dir.exist?(folder)).to eq(true)
      expect(File.exist?(symlink)).to eq(false)
    end

    context 'when dir is not in tmpdir' do
      it 'raises an error' do
        ['/etc', '/usr', '/', '/home', '/some/other/path', Rails.root.to_s].each do |path|
          expect { described_class.new(tmpdir: path, filename: 'filename').execute }
            .to raise_error(StandardError, "path #{path} is not allowed")
        end
      end
    end

    context 'when archive file is a symlink' do
      it 'raises an error' do
        FileUtils.ln_s(filepath, File.join(tmpdir, 'symlink'))

        expect { described_class.new(tmpdir: tmpdir, filename: 'symlink').execute }
          .to raise_error(BulkImports::Error, 'Invalid file')
      end
    end

    context 'when archive file shares multiple hard links' do
      it 'raises an error' do
        FileUtils.link(filepath, File.join(tmpdir, 'hard_link'))

        expect { subject.execute }.to raise_error(BulkImports::Error, 'Invalid file')
      end
    end

    context 'when filepath is being traversed' do
      it 'raises an error' do
        expect { described_class.new(tmpdir: File.join(Dir.mktmpdir, 'test', '..'), filename: 'name').execute }
          .to raise_error(Gitlab::PathTraversal::PathTraversalAttackError, 'Invalid path')
      end
    end
  end
end
