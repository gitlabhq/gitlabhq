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

    context "renamed file" do
      let(:project) { create(:project, :repository) }
      let(:commit) { project.commit('blame-on-renamed') }
      let(:path) { 'files/plain_text/renamed' }

      let(:blame) { described_class.new(project.repository, commit.id, path) }

      it do
        data = []
        blame.each do |commit, line, previous_path|
          data << {
            commit: commit,
            line: line,
            previous_path: previous_path
          }
        end

        expect(data.size).to eq(5)

        expect(data[0][:line]).to eq('Initial commit')
        expect(data[0][:previous_path]).to be nil
        expect(data[1][:line]).to eq('Initial commit')
        expect(data[1][:previous_path]).to be nil

        expect(data[2][:line]).to eq('Renamed as "filename"')
        expect(data[2][:previous_path]).to eq('files/plain_text/initial-commit')

        expect(data[3][:line]).to eq('Renamed as renamed')
        expect(data[3][:previous_path]).to eq('files/plain_text/"filename"')

        expect(data[4][:line]).to eq('Last edit, no rename')
        expect(data[4][:previous_path]).to eq('files/plain_text/renamed')
      end
    end
  end
end
