# frozen_string_literal: true

RSpec.shared_examples 'label note created from events' do
  def create_event(params = {})
    event_params = { action: :add, label: label, user: user }
    resource_key = resource.class.name.underscore.to_s
    event_params[resource_key] = resource

    build(:resource_label_event, event_params.merge(params))
  end

  def label_refs(events)
    labels = events.map(&:label).compact

    labels.map { |l| l.to_reference }.join(' ')
  end

  let(:time) { Time.now }
  let(:local_label_ids) { [label.id, label2.id] }

  describe '.from_events' do
    it 'returns system note with expected attributes' do
      event = create_event

      note = described_class.from_events([event, create_event])

      expect(note.system).to be true
      expect(note.author_id).to eq event.user_id
      expect(note.discussion_id).to eq event.discussion_id
      expect(note.noteable).to eq event.issuable
      expect(note.note).to be_present
      expect(note.note_html).to be_present
      expect(note.created_at).to eq create_event.created_at
      expect(note.updated_at).to eq create_event.created_at
    end

    it 'updates markdown cache if reference is not set yet' do
      event = create_event(reference: nil)

      described_class.from_events([event])

      expect(event.reference).not_to be_nil
    end

    it 'updates markdown cache if label was deleted' do
      event = create_event(reference: 'some_ref', label: nil)

      described_class.from_events([event])

      expect(event.reference).to eq ''
    end

    it 'returns html note' do
      events = [create_event(created_at: time)]

      note = described_class.from_events(events)

      expect(note.note_html).to include label.title
    end

    it 'returns text note for added labels' do
      events = [create_event(created_at: time),
        create_event(created_at: time, label: label2),
        create_event(created_at: time, label: nil)]

      note = described_class.from_events(events)

      expect(note.note).to eq "added #{label_refs(events)} + 1 deleted label"
    end

    it 'orders label events by label name' do
      foo_label = label.dup.tap do |l|
        l.update_attribute(:title, 'foo')
      end
      bar_label = label2.dup.tap do |l|
        l.update_attribute(:title, 'bar')
      end

      events = [
        create_event(created_at: time, label: foo_label),
        create_event(created_at: time, label: bar_label)
      ]

      note = described_class.from_events(events)

      expect(note.note).to eq "added #{label_refs(events.reverse)} labels"
    end

    it 'returns text note for removed labels' do
      events = [create_event(action: :remove, created_at: time),
        create_event(action: :remove, created_at: time, label: label2),
        create_event(action: :remove, created_at: time, label: nil)]

      note = described_class.from_events(events)

      expect(note.note).to eq "removed #{label_refs(events)} + 1 deleted label"
    end

    it 'returns text note for added and removed labels' do
      add_events = [create_event(created_at: time),
        create_event(created_at: time, label: nil)]

      remove_events = [create_event(action: :remove, created_at: time),
        create_event(action: :remove, created_at: time, label: nil)]

      note = described_class.from_events(add_events + remove_events)

      expect(note.note).to eq "added #{label_refs(add_events)} + 1 deleted label and removed #{label_refs(remove_events)} + 1 deleted label"
    end

    it 'returns text note for cross-project label' do
      other_label = create(:label)
      event = create_event(label: other_label)

      note = described_class.from_events([event])

      expect(note.note).to eq "added #{other_label.to_reference(resource_parent)} label"
    end

    it 'returns text note for cross-group label' do
      other_label = create(:group_label)
      event = create_event(label: other_label)

      note = described_class.from_events([event])

      expect(note.note).to eq "added #{other_label.to_reference(other_label.group, target_container: project, full: true)} label"
    end
  end
end
