# frozen_string_literal: true

RSpec.shared_examples 'issuable participants' do
  context 'when resource parent is public' do
    context 'and users are referenced on notes' do
      let_it_be(:notes_author) { create(:user) }

      let(:note_params) { params.merge(author: notes_author) }

      before do
        create(:note, note_params)
      end

      it 'includes the issue author' do
        expect(issuable.participants).to include(issuable.author)
      end

      it 'includes the authors of the notes' do
        expect(issuable.participants).to include(notes_author)
      end

      context 'and note is confidential' do
        context 'and mentions users' do
          let_it_be(:guest_1) { create(:user) }
          let_it_be(:guest_2) { create(:user) }
          let_it_be(:reporter) { create(:user) }

          before do
            issuable_parent.add_guest(guest_1)
            issuable_parent.add_guest(guest_2)
            issuable_parent.add_reporter(reporter)

            confidential_note_params =
              note_params.merge(
                confidential: true,
                note: "mentions #{guest_1.to_reference} and #{guest_2.to_reference} and #{reporter.to_reference}"
              )

            regular_note_params =
              note_params.merge(note: "Mentions #{guest_2.to_reference}")

            create(:note, confidential_note_params)
            create(:note, regular_note_params)
          end

          it 'only includes users that can read the note as participants' do
            expect(issuable.participants).to contain_exactly(issuable.author, notes_author, reporter, guest_2)
          end
        end
      end
    end
  end
end
