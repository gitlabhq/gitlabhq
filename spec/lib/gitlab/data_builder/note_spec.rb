require 'spec_helper'

describe Gitlab::DataBuilder::Note do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:data) { described_class.build(note, user) }
  let(:fixed_time) { Time.at(1425600000) } # Avoid time precision errors

  before do
    expect(data).to have_key(:object_attributes)
    expect(data[:object_attributes]).to have_key(:url)
    expect(data[:object_attributes][:url])
      .to eq(Gitlab::UrlBuilder.build(note))
    expect(data[:object_kind]).to eq('note')
    expect(data[:user]).to eq(user.hook_attrs)
  end

  describe 'When asking for a note on commit' do
    let(:note) { create(:note_on_commit, project: project) }

    it 'returns the note and commit-specific data' do
      expect(data).to have_key(:commit)
    end

    include_examples 'project hook data'
    include_examples 'deprecated repository hook data'
  end

  describe 'When asking for a note on commit diff' do
    let(:note) { create(:diff_note_on_commit, project: project) }

    it 'returns the note and commit-specific data' do
      expect(data).to have_key(:commit)
    end

    include_examples 'project hook data'
    include_examples 'deprecated repository hook data'
  end

  describe 'When asking for a note on issue' do
    let(:issue) do
      create(:issue, created_at: fixed_time, updated_at: fixed_time,
                     project: project)
    end

    let(:note) do
      create(:note_on_issue, noteable: issue, project: project)
    end

    it 'returns the note and issue-specific data' do
      expect(data).to have_key(:issue)
      expect(data[:issue].except('updated_at'))
        .to eq(issue.reload.hook_attrs.except('updated_at'))
      expect(data[:issue]['updated_at'])
        .to be > issue.hook_attrs['updated_at']
    end

    context 'with confidential issue' do
      let(:issue) { create(:issue, project: project, confidential: true) }

      it 'sets event_type to confidential_note' do
        expect(data[:event_type]).to eq('confidential_note')
      end
    end

    include_examples 'project hook data'
    include_examples 'deprecated repository hook data'
  end

  describe 'When asking for a note on merge request' do
    let(:merge_request) do
      create(:merge_request, created_at: fixed_time,
                             updated_at: fixed_time,
                             source_project: project)
    end

    let(:note) do
      create(:note_on_merge_request, noteable: merge_request,
                                     project: project)
    end

    it 'returns the note and merge request data' do
      expect(data).to have_key(:merge_request)
      expect(data[:merge_request].except('updated_at'))
        .to eq(merge_request.reload.hook_attrs.except('updated_at'))
      expect(data[:merge_request]['updated_at'])
        .to be > merge_request.hook_attrs['updated_at']
    end

    include_examples 'project hook data'
    include_examples 'deprecated repository hook data'
  end

  describe 'When asking for a note on merge request diff' do
    let(:merge_request) do
      create(:merge_request, created_at: fixed_time, updated_at: fixed_time,
                             source_project: project)
    end

    let(:note) do
      create(:diff_note_on_merge_request, noteable: merge_request,
                                          project: project)
    end

    it 'returns the note and merge request diff data' do
      expect(data).to have_key(:merge_request)
      expect(data[:merge_request].except('updated_at'))
        .to eq(merge_request.reload.hook_attrs.except('updated_at'))
      expect(data[:merge_request]['updated_at'])
        .to be > merge_request.hook_attrs['updated_at']
    end

    include_examples 'project hook data'
    include_examples 'deprecated repository hook data'
  end

  describe 'When asking for a note on project snippet' do
    let!(:snippet) do
      create(:project_snippet, created_at: fixed_time, updated_at: fixed_time,
                               project: project)
    end

    let!(:note) do
      create(:note_on_project_snippet, noteable: snippet,
                                       project: project)
    end

    it 'returns the note and project snippet data' do
      expect(data).to have_key(:snippet)
      expect(data[:snippet].except('updated_at'))
        .to eq(snippet.reload.hook_attrs.except('updated_at'))
      expect(data[:snippet]['updated_at'])
        .to be > snippet.hook_attrs['updated_at']
    end

    include_examples 'project hook data'
    include_examples 'deprecated repository hook data'
  end
end
