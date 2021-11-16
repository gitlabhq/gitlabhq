# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReleasePresenter do
  include Gitlab::Routing.url_helpers

  let_it_be(:project) { create(:project, :repository) }

  let(:developer) { create(:user) }
  let(:guest) { create(:user) }
  let(:user) { developer }
  let(:release) { create(:release, project: project) }
  let(:presenter) { described_class.new(release, current_user: user) }

  let(:base_url_params) { { scope: 'all', release_tag: release.tag } }
  let(:opened_url_params) { { state: 'opened', **base_url_params } }
  let(:merged_url_params) { { state: 'merged', **base_url_params } }
  let(:closed_url_params) { { state: 'closed', **base_url_params } }

  before do
    project.add_developer(developer)
    project.add_guest(guest)
  end

  describe '#commit_path' do
    subject { presenter.commit_path }

    it 'returns commit path' do
      is_expected.to eq(project_commit_path(project, release.commit.id))
    end

    context 'when commit is not found' do
      let(:release) { create(:release, project: project, sha: 'not-found') }

      it { is_expected.to be_nil }
    end

    context 'when user is guest' do
      let(:user) { guest }

      it { is_expected.to be_nil }
    end
  end

  describe '#tag_path' do
    subject { presenter.tag_path }

    it 'returns tag path' do
      is_expected.to eq(project_tag_path(project, release.tag))
    end

    context 'when user is guest' do
      let(:user) { guest }

      it { is_expected.to be_nil }
    end
  end

  describe '#self_url' do
    subject { presenter.self_url }

    it 'returns its own url' do
      is_expected.to eq(project_release_url(project, release))
    end
  end

  describe '#opened_merge_requests_url' do
    subject { presenter.opened_merge_requests_url }

    it 'returns merge requests url with state=open' do
      is_expected.to eq(project_merge_requests_url(project, opened_url_params))
    end
  end

  describe '#merged_merge_requests_url' do
    subject { presenter.merged_merge_requests_url }

    it 'returns merge requests url with state=merged' do
      is_expected.to eq(project_merge_requests_url(project, merged_url_params))
    end
  end

  describe '#closed_merge_requests_url' do
    subject { presenter.closed_merge_requests_url }

    it 'returns merge requests url with state=closed' do
      is_expected.to eq(project_merge_requests_url(project, closed_url_params))
    end
  end

  describe '#opened_issues_url' do
    subject { presenter.opened_issues_url }

    it 'returns issues url with state=open' do
      is_expected.to eq(project_issues_url(project, opened_url_params))
    end
  end

  describe '#closed_issues_url' do
    subject { presenter.closed_issues_url }

    it 'returns issues url with state=closed' do
      is_expected.to eq(project_issues_url(project, closed_url_params))
    end
  end

  describe '#edit_url' do
    subject { presenter.edit_url }

    it 'returns release edit url' do
      is_expected.to eq(edit_project_release_url(project, release))
    end

    context 'when a user is not allowed to update a release' do
      let(:presenter) { described_class.new(release, current_user: guest) }

      it { is_expected.to be_nil }
    end
  end

  describe '#assets_count' do
    subject { presenter.assets_count }

    it 'returns the number of assets associated to the release' do
      is_expected.to be release.assets_count
    end

    context 'when a user is not allowed to download release sources' do
      let(:presenter) { described_class.new(release, current_user: guest) }

      it 'returns the number of all non-source assets associated to the release' do
        is_expected.to be release.assets_count(except: [:sources])
      end
    end
  end

  describe '#name' do
    subject { presenter.name }

    it 'returns the release name' do
      is_expected.to eq release.name
    end
  end
end
