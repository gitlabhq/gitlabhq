# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AntiAbuse::Reports::Note, feature_category: :insider_threat do
  describe 'Concerns' do
    let_it_be(:factory) { :abuse_report_note }
    let_it_be(:discussion_factory) { :abuse_report_discussion_note }
    let_it_be(:note1) { create(:abuse_report_note, note: 'some note') }
    let_it_be(:note2) { create(:abuse_report_note) }
    let_it_be(:reply) { create(:abuse_report_note, in_reply_to: note1) }

    let_it_be_with_reload(:discussion_note) { create(:abuse_report_discussion_note) }
    let_it_be_with_reload(:discussion_note_2) do
      create(:abuse_report_discussion_note, abuse_report: discussion_note.abuse_report)
    end

    let_it_be_with_reload(:discussion_reply) do
      create(:abuse_report_discussion_note,
        abuse_report: discussion_note.abuse_report, in_reply_to: discussion_note)
    end

    it_behaves_like 'Notes::ActiveRecord'
    it_behaves_like 'Notes::Discussion'

    describe 'Validations' do
      it { is_expected.to validate_presence_of(:abuse_report) }
    end

    describe 'Callbacks' do
      it 'caches the html field' do
        expect(note1.note_html).to include('some note</p>')
      end
    end

    describe 'Scopes' do
      describe '.inc_relations_for_view' do
        subject(:incl_relations) { described_class.all.inc_relations_for_view.first }

        it 'loads associations' do
          expect(incl_relations.association(:author).loaded?).to be(true)
          expect(incl_relations.association(:updated_by).loaded?).to be(true)
          expect(incl_relations.association(:award_emoji).loaded?).to be(true)
        end
      end
    end

    describe '#parent_object_field' do
      it 'returns the correct value' do
        expect(described_class.parent_object_field).to eq(:abuse_report)
      end
    end

    describe '#skip_project_check?' do
      it 'returns true' do
        expect(note1.skip_project_check?).to eq(true)
      end
    end
  end
end
