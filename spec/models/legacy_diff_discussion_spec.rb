require 'spec_helper'

describe LegacyDiffDiscussion do
  subject { create(:legacy_diff_note_on_merge_request).to_discussion }

  describe '#reply_attributes' do
    it 'includes line_code' do
      expect(subject.reply_attributes[:line_code]).to eq(subject.line_code)
    end
  end

  describe '#merge_request_version_params' do
    context 'when the discussion is active' do
      before do
        allow(subject).to receive(:active?).and_return(true)
      end

      it 'returns an empty hash, which will end up showing the latest version' do
        expect(subject.merge_request_version_params).to eq({})
      end
    end

    context 'when the discussion is outdated' do
      before do
        allow(subject).to receive(:active?).and_return(false)
      end

      it 'returns nil' do
        expect(subject.merge_request_version_params).to be_nil
      end
    end
  end
end
