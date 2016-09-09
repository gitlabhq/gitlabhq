require 'spec_helper'

describe Gitlab::GithubImport::Importer, lib: true do
  describe '#execute' do
    context 'when an error occurs' do
      let(:project) { create(:project, import_url: 'https://github.com/octocat/Hello-World.git', wiki_enabled: false) }
      let(:octocat) { double(id: 123456, login: 'octocat') }
      let(:created_at) { DateTime.strptime('2011-01-26T19:01:12Z') }
      let(:updated_at) { DateTime.strptime('2011-01-27T19:01:12Z') }
      let(:repository) { double(id: 1, fork: false) }
      let(:source_sha) { create(:commit, project: project).id }
      let(:source_branch) { double(ref: 'feature', repo: repository, sha: source_sha) }
      let(:target_sha) { create(:commit, project: project, git_commit: RepoHelpers.another_sample_commit).id }
      let(:target_branch) { double(ref: 'master', repo: repository, sha: target_sha) }

      let(:label1) do
        double(
          name: 'Bug',
          color: 'ff0000',
          url: 'https://api.github.com/repos/octocat/Hello-World/labels/bug'
        )
      end

      let(:label2) do
        double(
          name: nil,
          color: 'ff0000',
          url: 'https://api.github.com/repos/octocat/Hello-World/labels/bug'
        )
      end

      let(:milestone) do
        double(
          number: 1347,
          state: 'open',
          title: '1.0',
          description: 'Version 1.0',
          due_on: nil,
          created_at: created_at,
          updated_at: updated_at,
          closed_at: nil,
          url: 'https://api.github.com/repos/octocat/Hello-World/milestones/1'
        )
      end

      let(:issue1) do
        double(
          number: 1347,
          milestone: nil,
          state: 'open',
          title: 'Found a bug',
          body: "I'm having a problem with this.",
          assignee: nil,
          user: octocat,
          comments: 0,
          pull_request: nil,
          created_at: created_at,
          updated_at: updated_at,
          closed_at: nil,
          url: 'https://api.github.com/repos/octocat/Hello-World/issues/1347'
        )
      end

      let(:issue2) do
        double(
          number: 1348,
          milestone: nil,
          state: 'open',
          title: nil,
          body: "I'm having a problem with this.",
          assignee: nil,
          user: octocat,
          comments: 0,
          pull_request: nil,
          created_at: created_at,
          updated_at: updated_at,
          closed_at: nil,
          url: 'https://api.github.com/repos/octocat/Hello-World/issues/1348'
        )
      end

      let(:pull_request) do
        double(
          number: 1347,
          milestone: nil,
          state: 'open',
          title: 'New feature',
          body: 'Please pull these awesome changes',
          head: source_branch,
          base: target_branch,
          assignee: nil,
          user: octocat,
          created_at: created_at,
          updated_at: updated_at,
          closed_at: nil,
          merged_at: nil,
          url: 'https://api.github.com/repos/octocat/Hello-World/pulls/1347'
        )
      end

      before do
        allow(project).to receive(:import_data).and_return(double.as_null_object)
        allow_any_instance_of(Octokit::Client).to receive(:rate_limit!).and_raise(Octokit::NotFound)
        allow_any_instance_of(Octokit::Client).to receive(:labels).and_return([label1, label2])
        allow_any_instance_of(Octokit::Client).to receive(:milestones).and_return([milestone, milestone])
        allow_any_instance_of(Octokit::Client).to receive(:issues).and_return([issue1, issue2])
        allow_any_instance_of(Octokit::Client).to receive(:pull_requests).and_return([pull_request, pull_request])
        allow_any_instance_of(Octokit::Client).to receive(:last_response).and_return(double(rels: { next: nil }))
        allow_any_instance_of(Gitlab::Shell).to receive(:import_repository).and_raise(Gitlab::Shell::Error)
      end

      it 'returns true' do
        expect(described_class.new(project).execute).to eq true
      end

      it 'does not raise an error' do
        expect { described_class.new(project).execute }.not_to raise_error
      end

      it 'stores error messages' do
        error = {
          message: 'The remote data could not be fully imported.',
          errors: [
            { type: :label, url: "https://api.github.com/repos/octocat/Hello-World/labels/bug", errors: "Validation failed: Title can't be blank, Title is invalid" },
            { type: :milestone, url: "https://api.github.com/repos/octocat/Hello-World/milestones/1", errors: "Validation failed: Title has already been taken" },
            { type: :issue, url: "https://api.github.com/repos/octocat/Hello-World/issues/1347", errors: "Invalid Repository. Use user/repo format." },
            { type: :issue, url: "https://api.github.com/repos/octocat/Hello-World/issues/1348", errors: "Validation failed: Title can't be blank, Title is too short (minimum is 0 characters)" },
            { type: :pull_request, url: "https://api.github.com/repos/octocat/Hello-World/pulls/1347", errors: "Invalid Repository. Use user/repo format." },
            { type: :pull_request, url: "https://api.github.com/repos/octocat/Hello-World/pulls/1347", errors: "Validation failed: Validate branches Cannot Create: This merge request already exists: [\"New feature\"]" },
            { type: :wiki, errors: "Gitlab::Shell::Error" }
          ]
        }

        described_class.new(project).execute

        expect(project.import_error).to eq error.to_json
      end
    end
  end
end
