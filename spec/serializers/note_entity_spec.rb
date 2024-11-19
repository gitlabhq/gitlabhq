# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NoteEntity, feature_category: :team_planning do
  include Gitlab::Routing

  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Persisted records required
  let_it_be(:note) { create(:note) }
  let_it_be(:user) { create(:user) }
  let_it_be(:email) { 'user@example.com' }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  let(:request) { double('request', current_user: user, noteable: note.noteable) }

  let(:entity) { described_class.new(note, request: request) }
  let(:obfuscated_email) { 'us*****@e*****.c**' }

  subject(:entity_hash) { entity.as_json }

  it_behaves_like 'note entity'

  context 'when note from external participant', feature_category: :service_desk do
    let!(:note_metadata) { build(:note_metadata, note: note) }

    subject { entity.as_json[:external_author] }

    it_behaves_like 'a field with obfuscated email address'
  end

  context 'when system note with issue_email_participants action', feature_category: :service_desk do
    let_it_be(:note_text) { "added #{email}" }
    # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Notes::RenderService updates #note and #cached_markdown_version
    let_it_be(:note) { create(:note, :system, author: Users::Internal.support_bot, note: note_text) }
    let_it_be(:system_note_metadata) { create(:system_note_metadata, note: note, action: :issue_email_participants) }
    # rubocop:enable RSpec/FactoryBot/AvoidCreate

    describe 'note' do
      subject { entity_hash[:note] }

      it_behaves_like 'a field with obfuscated email address'
    end

    describe 'note_html' do
      subject { entity_hash[:note_html] }

      it_behaves_like 'a field with obfuscated email address'
    end
  end
end
