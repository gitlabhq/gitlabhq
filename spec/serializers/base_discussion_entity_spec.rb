# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BaseDiscussionEntity, feature_category: :shared do
  let_it_be(:user) { create(:user) }
  let_it_be(:note) { create(:discussion_note_on_merge_request) }

  let(:request) { double('request', note_entity: ProjectNoteEntity) }
  let(:controller) { double('controller') }
  let(:entity) { described_class.new(discussion, request: request, context: controller) }
  let(:discussion) { note.discussion }

  subject(:json) { entity.as_json }

  before do
    allow(controller).to receive(:render_to_string)
    allow(request).to receive(:current_user).and_return(user)
    allow(request).to receive(:noteable).and_return(note.noteable)
  end

  it 'exposes correct attributes' do
    expect(json.keys).to contain_exactly(
      :commit_id,
      :confidential,
      :diff_discussion,
      :discussion_path,
      :expanded,
      :for_commit,
      :id,
      :individual_note,
      :project_id,
      :reply_id,
      :resolvable,
      :resolve_path,
      :resolve_with_issue_path,
      :resolved,
      :resolved_at,
      :resolved_by,
      :resolved_by_push
    )
  end

  context 'when discussion is not expanded' do
    include Gitlab::Routing

    let_it_be(:note) { create(:discussion_note, :on_work_item, :resolved) }

    it 'exposes correct attributes' do
      expect(json.keys).to contain_exactly(
        :commit_id,
        :confidential,
        :diff_discussion,
        :discussion_path,
        :expanded,
        :for_commit,
        :id,
        :individual_note,
        :project_id,
        :reply_id,
        :resolvable,
        :resolve_path,
        :resolved,
        :resolved_at,
        :resolved_by,
        :resolved_by_push,
        :truncated_diff_lines_path
      )

      expect(json[:truncated_diff_lines_path]).to eq(
        project_discussion_path(discussion.project, discussion.noteable_collection_name, note.noteable, discussion)
      )
    end
  end

  context 'when note is on an issue' do
    let_it_be(:note) { create(:discussion_note_on_issue) }

    it 'does not include resolve_with_issue_path' do
      expect(json.keys.sort).not_to include(:resolve_with_issue_path)
    end
  end

  context 'when is LegacyDiffDiscussion' do
    let(:project) { create(:project) }
    let(:merge_request) { create(:merge_request, source_project: project) }

    let(:discussion) do
      create(:legacy_diff_note_on_merge_request, noteable: merge_request, project: project).to_discussion
    end

    it 'exposes correct attributes' do
      expect(json.keys.sort).to include(
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
      expect(json.keys).to contain_exactly(
        :active,
        :commit_id,
        :confidential,
        :diff_discussion,
        :diff_file,
        :discussion_path,
        :expanded,
        :for_commit,
        :id,
        :individual_note,
        :line_code,
        :original_position,
        :position,
        :project_id,
        :reply_id,
        :resolvable,
        :resolve_path,
        :resolve_with_issue_path,
        :resolved,
        :resolved_at,
        :resolved_by,
        :resolved_by_push,
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
