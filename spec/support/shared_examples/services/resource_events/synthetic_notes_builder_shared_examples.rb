# frozen_string_literal: true

RSpec.shared_examples 'filters by paginated notes' do |event_type|
  let(:event) { create(event_type, issue: create(:issue)) }

  before do
    create(event_type, issue: event.issue)
  end

  it 'only returns given notes' do
    paginated_notes = { event_type.to_s.pluralize => [double(ids: [event.id])] }
    notes = described_class.new(event.issue, user, paginated_notes: paginated_notes).execute

    expect(notes.size).to eq(1)
    expect(notes.first.event).to eq(event)
  end

  context 'when paginated notes is empty' do
    it 'does not return any notes' do
      notes = described_class.new(event.issue, user, paginated_notes: {}).execute

      expect(notes.size).to eq(0)
    end
  end
end
