# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Git::Blame, :seed_helper do
  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '', 'group/project') }
  let(:blame) do
    Gitlab::Git::Blame.new(repository, SeedRepo::Commit::ID, "CONTRIBUTING.md")
  end

  describe 'blaming a file' do
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
        expect_next_instance_of(CharlockHolmes::EncodingDetector) do |detector|
          expect(detector).to receive(:detect).and_return(nil)
        end

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
end
