# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DataBuilder::Push, feature_category: :webhooks do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:user) { build(:user, public_email: 'public-email@example.com') }

  describe '.build' do
    let(:sample) { RepoHelpers.sample_compare }
    let(:commits) { project.repository.commits_between(sample.commits.first, sample.commits.last) }
    let(:project_hook_attrs) do
      {
        id: project.id,
        name: project.name,
        description: project.description,
        web_url: project.web_url,
        avatar_url: nil,
        git_ssh_url: project.ssh_url_to_repo,
        git_http_url: project.http_url_to_repo,
        namespace: project.namespace.name,
        visibility_level: project.visibility_level,
        path_with_namespace: project.full_path,
        default_branch: project.default_branch,
        ci_config_path: project.ci_config_path,
        homepage: project.web_url,
        url: project.url_to_repo,
        ssh_url: project.ssh_url_to_repo,
        http_url: project.http_url_to_repo
      }
    end

    before do
      allow(project).to receive(:hook_attrs).and_return(project_hook_attrs)
    end

    subject(:data) do
      described_class.build(project: project,
        user: user,
        ref: sample.target_branch,
        commits: commits,
        commits_count: Array(commits).length,
        message: 'test message',
        with_changed_files: with_changed_files)
    end

    context 'with changed files' do
      let(:with_changed_files) { true }

      context 'with batch_push_webhook_changed_paths enabled' do
        it 'returns commit hook data with changed files', :aggregate_failures do
          expect(Gitlab::GitalyClient).not_to receive(:allow_n_plus_1_calls)

          expect(data[:project]).to eq(project.hook_attrs)
          expect(data[:commits].first.keys).to include(*%i[added removed modified])
        end

        context 'with a commit that has no changed paths' do
          it 'does not fall back to per-commit deltas', :aggregate_failures do
            commit = commits.first

            allow(project.repository).to receive(:find_changed_paths!).and_return([])

            commit_payload = data[:commits].find { |payload| payload[:id] == commit.id }

            expect(commit_payload[:added]).to eq([])
            expect(commit_payload[:modified]).to eq([])
            expect(commit_payload[:removed]).to eq([])
          end
        end

        context 'with a merge commit' do
          let(:commits) { [project.repository.commit('60ecb67744cb56576c30214ff52294f8ce2def98')] }

          it 'matches legacy first-parent raw delta buckets', :aggregate_failures do
            expected_changes = { added: [], modified: ['.gitattributes'], removed: [] }

            commit_payload = data[:commits].first

            expect(commit_payload.slice(:added, :modified, :removed)).to eq(expected_changes)
            expect(commit_payload[:modified]).not_to include('README.md')
          end
        end

        context 'with merge and non-merge commits' do
          let(:merge_commit) { project.repository.commit('60ecb67744cb56576c30214ff52294f8ce2def98') }
          let(:non_merge_commit) { project.repository.commit('570e7b2abdd848b95f2f578043fc23bd6f6fd24d') }
          let(:commits) { [merge_commit, non_merge_commit] }

          it 'combines merge and non-merge changed path buckets in one build', :aggregate_failures do
            merge_payload = data[:commits].find { |payload| payload[:id] == merge_commit.id }
            non_merge_payload = data[:commits].find { |payload| payload[:id] == non_merge_commit.id }

            expect(merge_payload.slice(:added, :modified, :removed))
              .to eq(added: [], modified: ['.gitattributes'], removed: [])
            expect(merge_payload[:modified]).not_to include('README.md')
            expect(non_merge_payload.slice(:added, :modified, :removed))
              .to eq(added: [], modified: ['files/ruby/popen.rb', 'files/ruby/regex.rb'], removed: [])
          end
        end

        context 'with a pure rename' do
          let(:sample) { super().tap { |sample| sample.target_branch = 'refs/heads/gitaly-rename-test' } }
          let(:commits) { [project.repository.commit('94bb47ca1297b7b3731ff2a36923640991e9236f')] }

          it 'collapses the rename into a single added path, matching legacy behavior', :aggregate_failures do
            expect(data[:commits].first[:added]).to contain_exactly('CHANGELOG.md')
            expect(data[:commits].first[:removed]).to be_empty
          end
        end

        context 'with a single commit' do
          let(:commits) { project.repository.commit(sample.commits.first) }

          it 'returns commit hook data with changed files', :aggregate_failures do
            expect(data[:commits].size).to eq(1)
            expect(data[:commits].first.keys).to include(*%i[added removed modified])
          end
        end

        context 'with no commits' do
          let(:commits) { [] }

          it 'returns empty commits' do
            expect(data[:commits]).to be_empty
          end
        end
      end

      context 'with batch_push_webhook_changed_paths disabled' do
        before do
          stub_feature_flags(batch_push_webhook_changed_paths: false)
        end

        it 'returns changed files from per-commit raw deltas', :aggregate_failures do
          commit = commits.first

          expect(Gitlab::GitalyClient).to receive(:allow_n_plus_1_calls).and_call_original
          expect { data }.not_to raise_error

          commit_payload = data[:commits].find { |payload| payload[:id] == commit.id }

          expect(commit_payload.keys).to include(*%i[added removed modified])
          expect(commit_payload[:added]).to eq([])
          expect(commit_payload[:modified]).to eq([])
          expect(commit_payload[:removed]).to contain_exactly('.DS_Store', 'files/.DS_Store')
        end

        context 'with a pure rename' do
          let(:sample) { super().tap { |sample| sample.target_branch = 'refs/heads/gitaly-rename-test' } }
          let(:commits) { [project.repository.commit('94bb47ca1297b7b3731ff2a36923640991e9236f')] }

          it 'collapses the rename into a single added path, matching the enabled path', :aggregate_failures do
            expect(data[:commits].first[:added]).to contain_exactly('CHANGELOG.md')
            expect(data[:commits].first[:removed]).to be_empty
          end
        end
      end
    end

    context 'without changed files' do
      let(:with_changed_files) { false }

      it 'returns commit hook data without changed files', :aggregate_failures do
        expect(project.repository).not_to receive(:find_changed_paths!)

        expect(data[:project]).to eq(project.hook_attrs)
        expect(data[:commits].first.keys).not_to include(*%i[added removed modified])
      end
    end
  end

  describe '.build_sample push event' do
    let(:data) { described_class.build_sample(project, user) }

    it { expect(data[:object_kind]).to eq('push') }
    it { expect(data[:event_name]).to eq('push') }
    it { expect(data[:ref]).to eq('refs/heads/master') }

    include_examples 'project hook data with deprecateds'
    include_examples 'deprecated repository hook data'
    include_examples 'push hook data'
  end

  describe '.build_sample with tag push event' do
    let(:data) { described_class.build_sample(project, user, is_tag: true) }

    it { expect(data[:object_kind]).to eq('tag_push') }
    it { expect(data[:event_name]).to eq('tag_push') }
    it { expect(data[:ref]).to eq('refs/tags/v1.1.1') }

    describe "empty repository" do
      let_it_be(:project) { create(:project_empty_repo) }
      let(:data) { described_class.build_sample(project, user, is_tag: true) }

      it { expect(data[:ref]).to eq('refs/tags/v1.0.0') }
    end

    include_examples 'project hook data with deprecateds'
    include_examples 'deprecated repository hook data'
    include_examples 'push hook data'
  end

  describe '.sample_data' do
    let(:data) { described_class.sample_data }

    it { expect(data).to be_a(Hash) }
    it { expect(data[:before]).to eq('95790bf891e76fee5e1747ab589903a6a1f80f22') }
    it { expect(data[:after]).to eq('da1560886d4f094c3e6c9ef40349f7d38b5d27d7') }
    it { expect(data[:ref]).to eq('refs/heads/master') }
    it { expect(data[:project_id]).to eq(15) }
    it { expect(data[:commits].size).to eq(1) }
    it { expect(data[:total_commits_count]).to eq(1) }

    it 'contains project data' do
      expect(data[:project]).to be_a(Hash)
      expect(data[:project][:id]).to eq(15)
      expect(data[:project][:name]).to eq('gitlab')
      expect(data[:project][:description]).to eq('')
      expect(data[:project][:web_url]).to eq('http://test.example.com/gitlab/gitlab')
      expect(data[:project][:avatar_url]).to eq('https://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=8://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=80')
      expect(data[:project][:git_http_url]).to eq('http://test.example.com/gitlab/gitlab.git')
      expect(data[:project][:git_ssh_url]).to eq('git@test.example.com:gitlab/gitlab.git')
      expect(data[:project][:namespace]).to eq('gitlab')
      expect(data[:project][:visibility_level]).to eq(0)
      expect(data[:project][:path_with_namespace]).to eq('gitlab/gitlab')
      expect(data[:project][:default_branch]).to eq('master')
    end
  end

  describe '.build' do
    let(:data) do
      described_class.build(
        project: project,
        user: user,
        oldrev: Gitlab::Git::SHA1_BLANK_SHA,
        newrev: '8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b',
        ref: 'refs/tags/v1.1.0')
    end

    it { expect(data).to be_a(Hash) }
    it { expect(data[:before]).to eq(Gitlab::Git::SHA1_BLANK_SHA) }
    it { expect(data[:checkout_sha]).to eq('5937ac0a7beb003549fc5fd26fc247adbce4a52e') }
    it { expect(data[:after]).to eq('8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b') }
    it { expect(data[:ref]).to eq('refs/tags/v1.1.0') }
    it { expect(data[:user_id]).to eq(user.id) }
    it { expect(data[:user_name]).to eq(user.name) }
    it { expect(data[:user_username]).to eq(user.username) }
    it { expect(data[:user_email]).to eq(user.public_email) }
    it { expect(data[:user_avatar]).to eq(user.avatar_url) }
    it { expect(data[:project_id]).to eq(project.id) }
    it { expect(data[:project]).to be_a(Hash) }
    it { expect(data[:commits]).to be_empty }
    it { expect(data[:total_commits_count]).to be_zero }

    include_examples 'project hook data with deprecateds'
    include_examples 'deprecated repository hook data'

    it 'does not raise an error when given nil commits' do
      expect { described_class.build(project: spy, user: spy, ref: 'refs/tags/v1.1.0', commits: nil) }
        .not_to raise_error
    end
  end

  describe '.build_bulk' do
    subject do
      described_class.build_bulk(action: :created, ref_type: :branch, changes: [double, double])
    end

    it { is_expected.to eq(action: :created, ref_count: 2, ref_type: :branch) }
  end
end
