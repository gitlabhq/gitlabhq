# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Git::Blame, feature_category: :source_code_management do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository.raw }
  let(:sha) { TestEnv::BRANCH_SHA['master'] }
  let(:path) { 'CONTRIBUTING.md' }
  let(:range) { nil }
  let(:ignore_revisions_blob) { nil }

  let(:result) do
    [].tap do |data|
      blame.each do |commit, line, previous_path, span|
        data << { commit: commit, line: line, previous_path: previous_path, span: span }
      end
    end
  end

  subject(:blame) do
    described_class.new(repository, sha, path, range: range, ignore_revisions_blob: ignore_revisions_blob)
  end

  describe 'blaming a file' do
    it 'has the right commit span' do
      expect(result.first[:span]).to eq(95)
    end

    it 'has the right number of lines' do
      expect(result.size).to eq(95)
      expect(result.first[:commit]).to be_kind_of(Gitlab::Git::Commit)
      expect(result.first[:line]).to eq("# Contribute to GitLab")
      expect(result.first[:line]).to be_utf8
    end

    context 'blaming a range' do
      let(:range) { 2..4 }

      it 'only returns the range' do
        expect(result.size).to eq(range.size)
        expect(result.map { |r| r[:line] }).to eq(['', 'This guide details how contribute to GitLab.', ''])
      end

      context 'when range is outside of the file content range' do
        let(:range) { 9999..10000 }

        it 'returns an empty array' do
          expect(result).to eq([])
        end
      end
    end

    context 'when path is missing' do
      let(:path) { 'unknown_file' }

      it 'returns an empty array' do
        expect(result).to eq([])
      end
    end

    context "ISO-8859 encoding" do
      let(:path) { 'encoding/iso8859.txt' }

      it 'converts to UTF-8' do
        expect(result.size).to eq(1)
        expect(result.first[:commit]).to be_kind_of(Gitlab::Git::Commit)
        expect(result.first[:line]).to eq("Äü")
        expect(result.first[:line]).to be_utf8
      end
    end

    context "unknown encoding" do
      let(:path) { 'encoding/iso8859.txt' }

      it 'converts to UTF-8' do
        expect_next_instance_of(CharlockHolmes::EncodingDetector) do |detector|
          expect(detector).to receive(:detect).and_return(nil)
        end

        expect(result.size).to eq(1)
        expect(result.first[:commit]).to be_kind_of(Gitlab::Git::Commit)
        expect(result.first[:line]).to eq("")
        expect(result.first[:line]).to be_utf8
      end
    end

    context 'when repository has SHA256 format' do
      let_it_be(:user) { create(:user, :with_namespace) }

      let(:project) { Projects::CreateService.new(user, opts).execute }
      let(:opts) do
        {
          name: 'SHA256',
          namespace_id: user.namespace.id,
          initialize_with_readme: true,
          repository_object_format: 'sha256'
        }
      end

      let(:sha) { project.commit.sha }
      let(:path) { 'README.md' }

      it 'correctly blames file' do
        expect(result).to be_present
        expect(result.first[:commit].sha.size).to eq(64)
      end
    end

    context "renamed file" do
      let(:commit) { project.commit('blame-on-renamed') }
      let(:sha) { commit.id }
      let(:path) { 'files/plain_text/renamed' }

      it 'includes the previous path' do
        expect(result.size).to eq(5)

        expect(result[0]).to include(line: 'Initial commit', previous_path: nil)
        expect(result[1]).to include(line: 'Initial commit', previous_path: nil)
        expect(result[2]).to include(line: 'Renamed as "filename"', previous_path: 'files/plain_text/initial-commit')
        expect(result[3]).to include(line: 'Renamed as renamed', previous_path: 'files/plain_text/"filename"')
        expect(result[4]).to include(line: 'Last edit, no rename', previous_path: path)
      end
    end

    context 'with ignore_revisions_blob' do
      let(:ignore_revisions_blob) { 'reference_to_a_blob' }
      let(:commit_client_double) { instance_double(Gitlab::GitalyClient::CommitService, list_commits_by_oid: []) }

      before do
        allow(repository).to receive(:gitaly_commit_client).and_return(commit_client_double)
      end

      it 'requests raw blame with ignore_revisions_blob' do
        expect(commit_client_double).to receive(:raw_blame).with(
          sha,
          path,
          range: range,
          ignore_revisions_blob: ignore_revisions_blob
        ).and_return('')

        blame
      end
    end
  end
end
