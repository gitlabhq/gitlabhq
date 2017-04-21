require 'spec_helper'

describe LegacyDiffDiscussion, models: true do
  subject { create(:legacy_diff_note_on_merge_request).to_discussion }

  describe '#reply_attributes' do
    it 'includes line_code' do
      expect(subject.reply_attributes[:line_code]).to eq(subject.line_code)
    end
  end
end
