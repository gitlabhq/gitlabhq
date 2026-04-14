# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IndividualNoteDiscussion, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }

  describe '#can_convert_to_discussion?' do
    context 'when the note is a system note' do
      let(:note) { create(:note, :system, noteable: issue, project: project) }

      subject(:discussion) { note.to_discussion }

      it 'returns false' do
        expect(discussion.can_convert_to_discussion?).to be(false)
      end
    end

    context 'when the note is not a system note' do
      let(:note) { create(:note, noteable: issue, project: project) }

      subject(:discussion) { note.to_discussion }

      it 'returns true when noteable supports replying to individual notes' do
        allow(issue).to receive(:supports_replying_to_individual_notes?).and_return(true)

        expect(discussion.can_convert_to_discussion?).to be(true)
      end

      it 'returns false when noteable does not support replying to individual notes' do
        allow(issue).to receive(:supports_replying_to_individual_notes?).and_return(false)

        expect(discussion.can_convert_to_discussion?).to be(false)
      end
    end
  end
end
