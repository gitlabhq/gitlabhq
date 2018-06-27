require 'spec_helper'

describe Gitlab::BackgroundMigration::SetConfidentialNoteEventsOnServices, :migration, schema: 20180122154930 do
  let(:services) { table(:services) }

  describe '#perform' do
    it 'migrates services where note_events is true' do
      service = services.create(confidential_note_events: nil, note_events: true)

      subject.perform(service.id, service.id)

      expect(service.reload.confidential_note_events).to eq(true)
    end

    it 'ignores services where note_events is false' do
      service = services.create(confidential_note_events: nil, note_events: false)

      subject.perform(service.id, service.id)

      expect(service.reload.confidential_note_events).to eq(nil)
    end

    it 'ignores services where confidential_note_events has already been set' do
      service = services.create(confidential_note_events: false, note_events: true)

      subject.perform(service.id, service.id)

      expect(service.reload.confidential_note_events).to eq(false)
    end
  end
end
