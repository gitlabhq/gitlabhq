require 'spec_helper'

describe Gitlab::UrlBuilder, lib: true do
  describe 'When asking for an issue' do
    it 'returns the issue url' do
      issue = create(:issue)
      url = Gitlab::UrlBuilder.new(:issue).build(issue.id)
      expect(url).to eq "#{Settings.gitlab['url']}/#{issue.project.path_with_namespace}/issues/#{issue.iid}"
    end
  end

  describe 'When asking for an merge request' do
    it 'returns the merge request url' do
      merge_request = create(:merge_request)
      url = Gitlab::UrlBuilder.new(:merge_request).build(merge_request.id)
      expect(url).to eq "#{Settings.gitlab['url']}/#{merge_request.project.path_with_namespace}/merge_requests/#{merge_request.iid}"
    end
  end

  describe 'When asking for a note on commit' do
    let(:note) { create(:note_on_commit) }
    let(:url) { Gitlab::UrlBuilder.new(:note).build(note.id) }

    it 'returns the note url' do
      expect(url).to eq "#{Settings.gitlab['url']}/#{note.project.path_with_namespace}/commit/#{note.commit_id}#note_#{note.id}"
    end
  end

  describe 'When asking for a note on commit diff' do
    let(:note) { create(:note_on_commit_diff) }
    let(:url) { Gitlab::UrlBuilder.new(:note).build(note.id) }

    it 'returns the note url' do
      expect(url).to eq "#{Settings.gitlab['url']}/#{note.project.path_with_namespace}/commit/#{note.commit_id}#note_#{note.id}"
    end
  end

  describe 'When asking for a note on issue' do
    let(:issue) { create(:issue) }
    let(:note) { create(:note_on_issue, noteable_id: issue.id) }
    let(:url) { Gitlab::UrlBuilder.new(:note).build(note.id) }

    it 'returns the note url' do
      expect(url).to eq "#{Settings.gitlab['url']}/#{issue.project.path_with_namespace}/issues/#{issue.iid}#note_#{note.id}"
    end
  end

  describe 'When asking for a note on merge request' do
    let(:merge_request) { create(:merge_request) }
    let(:note) { create(:note_on_merge_request, noteable_id: merge_request.id) }
    let(:url) { Gitlab::UrlBuilder.new(:note).build(note.id) }

    it 'returns the note url' do
      expect(url).to eq "#{Settings.gitlab['url']}/#{merge_request.project.path_with_namespace}/merge_requests/#{merge_request.iid}#note_#{note.id}"
    end
  end

  describe 'When asking for a note on merge request diff' do
    let(:merge_request) { create(:merge_request) }
    let(:note) { create(:note_on_merge_request_diff, noteable_id: merge_request.id) }
    let(:url) { Gitlab::UrlBuilder.new(:note).build(note.id) }

    it 'returns the note url' do
      expect(url).to eq "#{Settings.gitlab['url']}/#{merge_request.project.path_with_namespace}/merge_requests/#{merge_request.iid}#note_#{note.id}"
    end
  end

  describe 'When asking for a note on project snippet' do
    let(:snippet) { create(:project_snippet) }
    let(:note) { create(:note_on_project_snippet, noteable_id: snippet.id) }
    let(:url) { Gitlab::UrlBuilder.new(:note).build(note.id) }

    it 'returns the note url' do
      expect(url).to eq "#{Settings.gitlab['url']}/#{snippet.project.path_with_namespace}/snippets/#{note.noteable_id}#note_#{note.id}"
    end
  end
end
