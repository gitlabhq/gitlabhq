# frozen_string_literal: true

RSpec.shared_examples 'has user mentions' do
  describe '#has_mentions?' do
    context 'when no mentions' do
      it 'returns false' do
        expect(subject.mentioned_users_ids).to be nil
        expect(subject.mentioned_projects_ids).to be nil
        expect(subject.mentioned_groups_ids).to be nil
        expect(subject.has_mentions?).to be false
      end
    end

    context 'when mentioned_users_ids not null' do
      subject { described_class.new(mentioned_users_ids: [1, 2, 3]) }

      it 'returns true' do
        expect(subject.has_mentions?).to be true
      end
    end

    context 'when mentioned projects' do
      subject { described_class.new(mentioned_projects_ids: [1, 2, 3]) }

      it 'returns true' do
        expect(subject.has_mentions?).to be true
      end
    end

    context 'when mentioned groups' do
      subject { described_class.new(mentioned_groups_ids: [1, 2, 3]) }

      it 'returns true' do
        expect(subject.has_mentions?).to be true
      end
    end

    context 'with mentions in notes' do
      let_it_be(:user) { create(:user) }
      let_it_be(:notes) { create_list(:note, 2) }
      let_it_be(:user_mention1) { described_class.create!(mentionable_key => mentionable.id, note: notes[0]) }
      let_it_be(:user_mention2) { described_class.create!(mentionable_key => mentionable.id, note: notes[1]) }

      it { expect(described_class.for_notes(notes)).to match_array([user_mention1, user_mention2]) }
      it { expect(described_class.for_notes(notes.map(&:id))).to match_array([user_mention1, user_mention2]) }

      it 'returns models for given notes AR relation' do
        # do not support cross join because Vulnerability is under separate DB schema
        unless described_class.name == 'VulnerabilityUserMention'
          expect(described_class.for_notes(::Note.id_in(notes))).to match_array([user_mention1, user_mention2])
        end
      end
    end
  end
end
