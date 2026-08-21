# frozen_string_literal: true

RSpec.shared_examples 'has user mentions' do
  let_it_be(:additional_params, freeze: false) { {} }
  let_it_be(:notes_factory) { :note }

  describe '.for_notes' do
    let_it_be(:user, freeze: false) { create(:user) }
    let_it_be(:notes, freeze: false) { create_list(notes_factory, 2) }
    let_it_be(:user_mention1, freeze: false) do
      described_class.create!(additional_params.merge(mentionable_key => mentionable.id, note: notes[0]))
    end

    let_it_be(:user_mention2, freeze: false) do
      described_class.create!(additional_params.merge(mentionable_key => mentionable.id, note: notes[1]))
    end

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
