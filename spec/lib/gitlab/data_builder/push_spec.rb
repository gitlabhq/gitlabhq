# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DataBuilder::Push do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:user) { build(:user, public_email: 'public-email@example.com') }

  describe '.build' do
    let(:sample) { RepoHelpers.sample_compare }
    let(:commits) { project.repository.commits_between(sample.commits.first, sample.commits.last) }
    let(:subject) do
      described_class.build(project: project,
        user: user,
        ref: sample.target_branch,
        commits: commits,
        commits_count: commits.length,
        message: 'test message',
        with_changed_files: with_changed_files)
    end

    context 'with changed files' do
      let(:with_changed_files) { true }

      it 'returns commit hook data' do
        expect(subject[:project]).to eq(project.hook_attrs)
        expect(subject[:commits].first.keys).to include(*%i[added removed modified])
      end
    end

    context 'without changed files' do
      let(:with_changed_files) { false }

      it 'returns commit hook data without include deltas' do
        expect(subject[:project]).to eq(project.hook_attrs)
        expect(subject[:commits].first.keys).not_to include(*%i[added removed modified])
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
