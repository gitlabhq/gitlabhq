# frozen_string_literal: true

RSpec.shared_examples 'listing issuable discussions' do |user_role:, internal_discussions:, total_discussions:|
  before_all do
    create_notes(issuable, "some user comment")

    if issuable.try(:sync_object).present?
      create_notes(issuable.sync_object, "some user comment")
      internal_discussions *= 2
      total_discussions *= 2
    end
  end

  context 'when user cannot read issue' do
    it "returns no notes" do
      expect(discussions_service.execute).to be_empty
    end
  end

  context 'when user can read issuable' do
    before do
      group.add_developer(current_user)
    end

    context 'with paginated results' do
      let(:finder_params_for_issuable) { { per_page: 2 } }
      let(:next_page_cursor) { { cursor: discussions_service.paginator.cursor_for_next_page } }

      it "returns next page notes" do
        next_page_discussions_service = described_class.new(current_user, issuable,
          finder_params_for_issuable.merge(next_page_cursor))
        discussions = next_page_discussions_service.execute

        expect(discussions.count).to eq(2)
        expect(discussions.first.notes.map(&:note)).to match_array(
          ["added #{label.to_reference} #{label_2.to_reference} labels"]
        )
        expect(discussions.second.notes.map(&:note)).to match_array(["removed #{label.to_reference} label"])
      end
    end

    # confidential notes are currently available only on issues and epics
    context 'and cannot read confidential notes' do
      before do
        group.add_member(current_user, user_role)
      end

      it "returns non confidential notes" do
        discussions = discussions_service.execute
        non_conf_discussion_count = total_discussions - internal_discussions
        expect(discussions.count).to eq(non_conf_discussion_count)
        expect(discussions.count { |disc| disc.notes.any?(&:confidential) }).to eq(0)
        expect(discussions.count { |disc| !disc.notes.any?(&:confidential) }).to eq(non_conf_discussion_count)
      end
    end

    # confidential notes are currently available only on issues and epics
    context 'and can read confidential notes' do
      it "returns all notes" do
        discussions = discussions_service.execute
        expect(discussions.count).to eq(total_discussions)
        expect(discussions.count { |disc| disc.notes.any?(&:confidential) }).to eq(internal_discussions)
        non_conf_discussion_count = total_discussions - internal_discussions
        expect(discussions.count { |disc| !disc.notes.any?(&:confidential) }).to eq(non_conf_discussion_count)
      end
    end

    context 'and system notes only' do
      let(:finder_params_for_issuable) { { notes_filter: UserPreference::NOTES_FILTERS[:only_activity] } }

      it "returns system notes" do
        discussions = discussions_service.execute

        expect(discussions.count { |disc| disc.notes.any?(&:system) }).to be > 0
        expect(discussions.count { |disc| !disc.notes.any?(&:system) }).to eq(0)
      end
    end

    context 'and user comments only' do
      let(:finder_params_for_issuable) { { notes_filter: UserPreference::NOTES_FILTERS[:only_comments] } }

      it "returns user comments" do
        discussions = discussions_service.execute

        expect(discussions.count { |disc| disc.notes.any?(&:system) }).to eq(0)
        expect(discussions.count { |disc| !disc.notes.any?(&:system) }).to be > 0
      end
    end
  end
end

def create_notes(issuable, note_body)
  assoc_name = issuable.to_ability_name

  create(:note, system: true, project: issuable.project, noteable: issuable)

  first_discussion = create(:discussion_note_on_issue, noteable: issuable, project: issuable.project, note: note_body)
  create(:note,
    discussion_id: first_discussion.discussion_id, noteable: issuable,
    project: issuable.project, note: "reply on #{note_body}")

  now = Time.current
  create(
    :resource_label_event,
    user: current_user, "#{assoc_name}": issuable, label: label, action: 'add', created_at: now
  )
  create(
    :resource_label_event,
    user: current_user, "#{assoc_name}": issuable, label: label_2, action: 'add', created_at: now
  )
  create(:resource_label_event, user: current_user, "#{assoc_name}": issuable, label: label, action: 'remove')

  if !issuable.is_a?(Epic) && !(issuable.is_a?(WorkItem) && issuable.work_item_type.name == 'Epic')
    create(:resource_milestone_event, "#{assoc_name}": issuable, milestone: milestone, action: 'add')
    create(:resource_milestone_event, "#{assoc_name}": issuable, milestone: milestone, action: 'remove')
  end

  # confidential notes are currently available only on issues and epics
  return unless issuable.is_a?(Issue) || issuable.is_a?(Epic)

  first_internal_discussion = create(:discussion_note_on_issue, :confidential,
    noteable: issuable, project: issuable.project, note: "confidential #{note_body}")
  create(:note, :confidential,
    discussion_id: first_internal_discussion.discussion_id, noteable: issuable,
    project: issuable.project, note: "reply on confidential #{note_body}")
end
