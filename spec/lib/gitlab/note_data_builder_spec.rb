require 'spec_helper'

describe 'Gitlab::NoteDataBuilder' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:data) { Gitlab::NoteDataBuilder.build(note, user) }
  let(:note_url) { Gitlab::UrlBuilder.new(:note).build(note.id) }
  let(:fixed_time) { Time.at(1425600000) } # Avoid time precision errors

  before(:each) do
    expect(data).to have_key(:object_attributes)
    expect(data[:object_attributes]).to have_key(:url)
    expect(data[:object_attributes][:url]).to eq(note_url)
    expect(data[:object_kind]).to eq('note')
    expect(data[:user]).to eq(user.hook_attrs)
  end

  describe 'When asking for a note on commit' do
    let(:note) { create(:note_on_commit) }

    it 'returns the note and commit-specific data' do
      expect(data).to have_key(:commit)
    end
  end

  describe 'When asking for a note on commit diff' do
    let(:note) { create(:note_on_commit_diff) }

    it 'returns the note and commit-specific data' do
      expect(data).to have_key(:commit)
    end
  end

  describe 'When asking for a note on issue' do
    let(:issue) { create(:issue, created_at: fixed_time, updated_at: fixed_time) }
    let(:note) { create(:note_on_issue, noteable_id: issue.id) }

    it 'returns the note and issue-specific data' do
      expect(data).to have_key(:issue)
      expect(data[:issue]).to eq(issue.hook_attrs)
    end
  end

  describe 'When asking for a note on merge request' do
    let(:merge_request) { create(:merge_request, created_at: fixed_time, updated_at: fixed_time) }
    let(:note) { create(:note_on_merge_request, noteable_id: merge_request.id) }

    it 'returns the note and merge request data' do
      expect(data).to have_key(:merge_request)
      expect(data[:merge_request]).to eq(merge_request.hook_attrs)
    end
  end

  describe 'When asking for a note on merge request diff' do
    let(:merge_request) { create(:merge_request, created_at: fixed_time, updated_at: fixed_time) }
    let(:note) { create(:note_on_merge_request_diff, noteable_id: merge_request.id) }

    it 'returns the note and merge request diff data' do
      expect(data).to have_key(:merge_request)
      expect(data[:merge_request]).to eq(merge_request.hook_attrs)
    end
  end

  describe 'When asking for a note on project snippet' do
    let!(:snippet) { create(:project_snippet, created_at: fixed_time, updated_at: fixed_time) }
    let!(:note) { create(:note_on_project_snippet, noteable_id: snippet.id) }

    it 'returns the note and project snippet data' do
      expect(data).to have_key(:snippet)
      expect(data[:snippet]).to eq(snippet.hook_attrs)
    end
  end
end
