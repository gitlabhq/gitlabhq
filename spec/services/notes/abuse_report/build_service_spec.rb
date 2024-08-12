# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::AbuseReport::BuildService, feature_category: :team_planning do
  let_it_be(:abuse_report) { create(:abuse_report) }
  let_it_be(:user) { create(:admin) }
  let_it_be(:author) { create(:admin) }
  let_it_be(:note) { create(:abuse_report_discussion_note, abuse_report: abuse_report, author: author) }
  let_it_be(:individual_note) { create(:abuse_report_note, abuse_report: abuse_report, author: author) }
  let_it_be(:other_user) { create(:user) }

  let(:note_content) { 'Awesome comment' }
  let(:base_params) { { note: note_content, abuse_report: abuse_report } }
  let(:params) { {} }
  let(:executing_user) { nil }

  subject(:new_note) do
    described_class.new(user, base_params.merge(params)).execute(executing_user: executing_user)
  end

  describe '#execute', :enable_admin_mode do
    context 'with simple params' do
      it 'creates a valid note' do
        expect(new_note).to be_valid
        expect(new_note.note).to eq(note_content)
      end
    end

    context 'when in_reply_to_discussion_id is specified' do
      let(:discussion_class) { AntiAbuse::Reports::DiscussionNote }
      let(:params) { { in_reply_to_discussion_id: note.discussion_id } }

      it_behaves_like 'building notes replying to another note'
    end
  end
end
