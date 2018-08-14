require 'spec_helper'

describe DiscussionEntity do
  include RepoHelpers

  let(:user) { create(:user) }
  let(:note) { create(:discussion_note_on_merge_request) }
  let(:discussion) { note.discussion }
  let(:request) { double('request', note_entity: ProjectNoteEntity) }
  let(:controller) { double('controller') }
  let(:entity) { described_class.new(discussion, request: request, context: controller) }

  subject { entity.as_json }

  before do
    allow(controller).to receive(:render_to_string)
    allow(request).to receive(:current_user).and_return(user)
    allow(request).to receive(:noteable).and_return(note.noteable)
  end

  it 'exposes correct attributes' do
    expect(subject.keys.sort).to include(
      :diff_discussion,
      :expanded,
      :id,
      :individual_note,
      :notes,
      :resolvable,
      :resolve_path,
      :resolve_with_issue_path,
      :resolved,
      :discussion_path,
      :resolved_at,
      :for_commit,
      :commit_id
    )
  end

  context 'when is LegacyDiffDiscussion' do
    let(:project) { create(:project) }
    let(:merge_request) { create(:merge_request, source_project: project) }
    let(:discussion) { create(:legacy_diff_note_on_merge_request, noteable: merge_request, project: project).to_discussion }

    it 'exposes correct attributes' do
      expect(subject.keys.sort).to include(
        :diff_discussion,
        :expanded,
        :id,
        :individual_note,
        :notes,
        :discussion_path,
        :for_commit,
        :commit_id
      )
    end
  end

  context 'when diff file is present' do
    let(:note) { create(:diff_note_on_merge_request) }

    it 'exposes diff file attributes' do
      expect(subject.keys.sort).to include(
        :diff_file,
        :truncated_diff_lines,
        :position,
        :line_code,
        :active
      )
    end

    context 'when diff file is a image' do
      it 'exposes image attributes' do
        allow(discussion).to receive(:on_image?).and_return(true)

        expect(subject.keys).to include(:image_diff_html)
      end
    end
  end
end
