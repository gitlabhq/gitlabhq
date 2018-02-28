# coding: utf-8
require "spec_helper"

describe Gitlab::Git::Blame, seed_helper: true do
  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '') }
  let(:blame) do
    Gitlab::Git::Blame.new(repository, SeedRepo::Commit::ID, "CONTRIBUTING.md")
  end

  shared_examples 'blaming a file' do
    context "each count" do
      it do
        data = []
        blame.each do |commit, line|
          data << {
            commit: commit,
            line: line
          }
        end

        expect(data.size).to eq(95)
        expect(data.first[:commit]).to be_kind_of(Gitlab::Git::Commit)
        expect(data.first[:line]).to eq("# Contribute to GitLab")
        expect(data.first[:line]).to be_utf8
      end
    end

    context "ISO-8859 encoding" do
      let(:blame) do
        Gitlab::Git::Blame.new(repository, SeedRepo::EncodingCommit::ID, "encoding/iso8859.txt")
      end

      it 'converts to UTF-8' do
        data = []
        blame.each do |commit, line|
          data << {
            commit: commit,
            line: line
          }
        end

        expect(data.size).to eq(1)
        expect(data.first[:commit]).to be_kind_of(Gitlab::Git::Commit)
        expect(data.first[:line]).to eq("Ä ü")
        expect(data.first[:line]).to be_utf8
      end
    end

    context "unknown encoding" do
      let(:blame) do
        Gitlab::Git::Blame.new(repository, SeedRepo::EncodingCommit::ID, "encoding/iso8859.txt")
      end

      it 'converts to UTF-8' do
        expect(CharlockHolmes::EncodingDetector).to receive(:detect).and_return(nil)
        data = []
        blame.each do |commit, line|
          data << {
            commit: commit,
            line: line
          }
        end

        expect(data.size).to eq(1)
        expect(data.first[:commit]).to be_kind_of(Gitlab::Git::Commit)
        expect(data.first[:line]).to eq(" ")
        expect(data.first[:line]).to be_utf8
      end
    end
  end

  context 'when Gitaly blame feature is enabled' do
    it_behaves_like 'blaming a file'
  end

  context 'when Gitaly blame feature is disabled', :skip_gitaly_mock do
    it_behaves_like 'blaming a file'
  end
end
