require 'spec_helper'

describe Gitlab::LightUrlBuilder, lib: true do
  context 'when passing a Commit' do
    it 'returns a proper URL' do
      commit = build_stubbed(:commit)

      url = described_class.build(entity: :commit, project: commit.project, id: commit.id)

      expect(url).to eq "#{Settings.gitlab['url']}/#{commit.project.path_with_namespace}/commit/#{commit.id}"
    end
  end

  context 'when passing an Issue' do
    it 'returns a proper URL' do
      issue = build_stubbed(:issue, iid: 42)

      url = described_class.build(entity: :issue, project: issue.project, id: issue.iid)

      expect(url).to eq "#{Settings.gitlab['url']}/#{issue.project.path_with_namespace}/issues/#{issue.iid}"
    end
  end

  context 'when passing a MergeRequest' do
    it 'returns a proper URL' do
      merge_request = build_stubbed(:merge_request, iid: 42)

      url = described_class.build(entity: :merge_request, project: merge_request.project, id: merge_request.iid)

      expect(url).to eq "#{Settings.gitlab['url']}/#{merge_request.project.path_with_namespace}/merge_requests/#{merge_request.iid}"
    end
  end

  context 'when passing a build' do
    it 'returns a proper URL' do
      build = build_stubbed(:ci_build, project: build_stubbed(:empty_project))

      url = described_class.build(entity: :build, project: build.project, id: build.id)

      expect(url).to eq "#{Settings.gitlab['url']}/#{build.project.path_with_namespace}/builds/#{build.id}"
    end
  end

  context 'when passing a branch' do
    it 'returns a proper URL' do
      branch = 'branch_name'
      project = build_stubbed(:empty_project)

      url = described_class.build(entity: :branch, project: project, id: branch)

      expect(url).to eq "#{Settings.gitlab['url']}/#{project.path_with_namespace}/commits/#{branch}"
    end
  end

  context 'on a User' do
    it 'returns a proper URL' do
      user = build_stubbed(:user)

      url = described_class.build(entity: :user, id: user.username)

      expect(url).to eq "#{Settings.gitlab['url']}/#{user.username}"
    end
  end

  context 'on a user avatar' do
    it 'returns a proper URL' do
      user = create(:user)

      url = described_class.build(entity: :user_avatar, id: user.id)

      expect(url).to eq user.avatar_url
    end
  end
end
