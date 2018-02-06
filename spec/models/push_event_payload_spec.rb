require 'spec_helper'

describe PushEventPayload do
  describe 'saving payloads' do
    it 'does not allow commit messages longer than 70 characters' do
      event = create(:push_event)
      payload = build(:push_event_payload, event: event)

      expect(payload).to be_valid

      payload.commit_title = 'a' * 100

      expect(payload).not_to be_valid
    end
  end
end
