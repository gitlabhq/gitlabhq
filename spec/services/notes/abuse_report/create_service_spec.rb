# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::AbuseReport::CreateService, feature_category: :insider_threat do
  let_it_be(:abuse_report) { create(:abuse_report) }
  let_it_be(:user) { create(:admin) }

  let(:note_content) { 'Awesome comment' }
  let(:base_opts) { { note: note_content, abuse_report_id: abuse_report.id } }
  let(:opts) { base_opts }

  describe '#execute', :enable_admin_mode do
    subject(:create_note) { described_class.new(user, opts).execute }

    context 'with valid params' do
      it 'creates a note correctly', :aggregate_failures do
        expect { create_note }.to change { AntiAbuse::Reports::Note.count }.by(1)

        created_note = AntiAbuse::Reports::Note.last

        expect(created_note.abuse_report).to eq(abuse_report)
        expect(created_note.note).to eq('Awesome comment')
      end

      context 'when note has only an emoji' do
        let(:note_content) { ':smile:' }

        it 'creates regular note' do
          note = create_note

          expect(note).to be_valid
          expect(note.note).to eq(':smile:')
        end
      end

      context 'when replying to an individual note' do
        let_it_be(:existing_note) { create(:abuse_report_note, abuse_report: abuse_report) }

        let(:opts) { base_opts.merge(in_reply_to_discussion_id: existing_note.discussion_id) }

        it 'creates a DiscussionNote in reply to existing note' do
          result = create_note

          expect(result).to be_a(AntiAbuse::Reports::DiscussionNote)
          expect(result.discussion_id).to eq(existing_note.discussion_id)
        end

        it 'converts existing note to DiscussionNote' do
          expect do
            existing_note

            travel_to(Time.current + 1.minute) { create_note }

            existing_note.reload
          end.to change { existing_note.type }.from(nil).to('AntiAbuse::Reports::DiscussionNote')
                                              .and change { existing_note.updated_at }
        end
      end
    end
  end
end
