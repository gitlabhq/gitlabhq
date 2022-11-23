# frozen_string_literal: true

# This shared_example includes the following option:
# - notes: any of [:new_alert, :recovery_alert, :resolve_alert].
#          Represents which notes are expected to be created.
#
# This shared_example requires the following variables:
# - `source` (optional), the monitoring tool or integration name
#                        expected in the applicable system notes
RSpec.shared_examples 'creates expected system notes for alert' do |*notes|
  let(:expected_note_count) { expected_notes.length }
  let(:new_notes) { Note.last(expected_note_count).pluck(:note) }
  let(:expected_notes) do
    {
      new_alert: source,
      recovery_alert: source,
      resolve_alert: 'Resolved'
    }.slice(*notes)
  end

  it "for #{notes.join(', ')}" do
    expect { subject }.to change { Note.count }.by(expected_note_count)

    expected_notes.each_value.with_index do |value, index|
      expect(new_notes[index]).to include(value)
    end
  end
end

RSpec.shared_examples 'does not create a system note for alert' do
  specify do
    expect { subject }.not_to change { Note.count }
  end
end
