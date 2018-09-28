require 'spec_helper'

describe Gitlab::BackgroundMigration::SetConfidentialNoteEventsOnWebhooks, :migration, schema: 20180104131052 do
  let(:web_hooks) { table(:web_hooks) }

  describe '#perform' do
    it 'migrates hooks where note_events is true' do
      hook = web_hooks.create(confidential_note_events: nil, note_events: true)

      subject.perform(hook.id, hook.id)

      expect(hook.reload.confidential_note_events).to eq(true)
    end

    it 'ignores hooks where note_events is false' do
      hook = web_hooks.create(confidential_note_events: nil, note_events: false)

      subject.perform(hook.id, hook.id)

      expect(hook.reload.confidential_note_events).to eq(nil)
    end

    it 'ignores hooks where confidential_note_events has already been set' do
      hook = web_hooks.create(confidential_note_events: false, note_events: true)

      subject.perform(hook.id, hook.id)

      expect(hook.reload.confidential_note_events).to eq(false)
    end
  end
end
