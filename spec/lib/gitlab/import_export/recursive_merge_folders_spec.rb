# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::RecursiveMergeFolders do
  describe '.merge' do
    it 'merges folder and ignores symlinks and files that share hard links' do
      Dir.mktmpdir do |tmpdir|
        source = "#{tmpdir}/source"
        FileUtils.mkdir_p("#{source}/folder/folder")
        FileUtils.touch("#{source}/file1.txt")
        FileUtils.touch("#{source}/file_that_shares_hard_links.txt")
        FileUtils.touch("#{source}/folder/file2.txt")
        FileUtils.touch("#{source}/folder/folder/file3.txt")
        FileUtils.ln_s("#{source}/file1.txt", "#{source}/symlink-file1.txt")
        FileUtils.ln_s("#{source}/folder", "#{source}/symlink-folder")
        FileUtils.link("#{source}/file_that_shares_hard_links.txt", "#{source}/hard_link.txt")

        target = "#{tmpdir}/target"
        FileUtils.mkdir_p("#{target}/folder/folder")
        FileUtils.mkdir_p("#{target}/folderA")
        FileUtils.touch("#{target}/fileA.txt")

        described_class.merge(source, target)

        expect(Dir.children("#{tmpdir}/target")).to match_array(%w[folder file1.txt folderA fileA.txt])
        expect(Dir.children("#{tmpdir}/target/folder")).to match_array(%w[folder file2.txt])
        expect(Dir.children("#{tmpdir}/target/folder/folder")).to match_array(%w[file3.txt])
      end
    end

    it 'raises an error for invalid source path' do
      Dir.mktmpdir do |tmpdir|
        expect do
          described_class.merge("#{tmpdir}/../", tmpdir)
        end.to raise_error(Gitlab::PathTraversal::PathTraversalAttackError)
      end
    end

    it 'raises an error for source path outside temp dir' do
      Dir.mktmpdir do |tmpdir|
        expect do
          described_class.merge('/', tmpdir)
        end.to raise_error(StandardError, 'path / is not allowed')
      end
    end

    it 'raises an error for invalid target path' do
      Dir.mktmpdir do |tmpdir|
        expect do
          described_class.merge(tmpdir, "#{tmpdir}/../")
        end.to raise_error(Gitlab::PathTraversal::PathTraversalAttackError)
      end
    end
  end
end
