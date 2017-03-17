require 'spec_helper'

describe SimpleDiscussion, model: true do
  subject { create(:discussion_note_on_issue).to_discussion }

  describe '#reply_attributes' do
    it 'includes discussion_id' do
      expect(subject.reply_attributes[:discussion_id]).to eq(subject.id)
    end
  end
end
