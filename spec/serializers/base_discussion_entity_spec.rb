# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BaseDiscussionEntity do
  let_it_be(:user) { create(:user) }
  let_it_be(:note) { create(:discussion_note_on_merge_request) }

  let(:request) { double('request', note_entity: ProjectNoteEntity) }
  let(:controller) { double('controller') }
  let(:entity) { described_class.new(discussion, request: request, context: controller) }
  let(:discussion) { note.discussion }

  subject { entity.as_json }

  before do
    allow(controller).to receive(:render_to_string)
    allow(request).to receive(:current_user).and_return(user)
    allow(request).to receive(:noteable).and_return(note.noteable)
  end

  it 'exposes correct attributes' do
    expect(subject.keys.sort).to include(
      :commit_id,
      :confidential,
      :diff_discussion,
      :discussion_path,
      :expanded,
      :for_commit,
      :id,
      :individual_note,
      :resolvable,
      :resolve_path,
      :resolve_with_issue_path
    )
  end

  context 'when is LegacyDiffDiscussion' do
    let(:project) { create(:project) }
    let(:merge_request) { create(:merge_request, source_project: project) }
    let(:discussion) { create(:legacy_diff_note_on_merge_request, noteable: merge_request, project: project).to_discussion }

    it 'exposes correct attributes' do
      expect(subject.keys.sort).to include(
        :commit_id,
        :diff_discussion,
        :discussion_path,
        :expanded,
        :for_commit,
        :id,
        :individual_note
      )
    end
  end

  context 'when diff file is present' do
    let(:note) { create(:diff_note_on_merge_request) }

    it 'exposes diff file attributes' do
      expect(subject.keys.sort).to include(
        :active,
        :diff_file,
        :line_code,
        :position,
        :truncated_diff_lines
      )
    end
  end

  context 'when issues are disabled in a project' do
    let(:project) { create(:project, :issues_disabled) }
    let(:note) { create(:discussion_note_on_merge_request, project: project) }

    it 'does not show a new issues path' do
      expect(entity.as_json[:resolve_with_issue_path]).to be_nil
    end
  end
end
