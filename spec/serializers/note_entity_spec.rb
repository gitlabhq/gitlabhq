# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NoteEntity, feature_category: :team_planning do
  include Gitlab::Routing

  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Persisted records required
  let_it_be(:note) { create(:note) }
  let_it_be(:user) { create(:user) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  let(:request) { double('request', current_user: user, noteable: note.noteable) }

  let(:entity) { described_class.new(note, request: request) }

  subject(:entity_hash) { entity.as_json }

  it_behaves_like 'note entity'

  shared_examples 'external author' do
    context 'when anonymous' do
      let(:user) { nil }

      it { is_expected.to eq(obfuscated_email) }
    end

    context 'with signed in user' do
      before do
        stub_member_access_level(note.project, access_level => user) if access_level
      end

      context 'when user has no role in project' do
        let(:access_level) { nil }

        it { is_expected.to eq(obfuscated_email) }
      end

      context 'when user has guest role in project' do
        let(:access_level) { :guest }

        it { is_expected.to eq(obfuscated_email) }
      end

      context 'when user has reporter role in project' do
        let(:access_level) { :reporter }

        it { is_expected.to eq(email) }
      end

      context 'when user has developer role in project' do
        let(:access_level) { :developer }

        it { is_expected.to eq(email) }
      end
    end
  end

  describe 'with email participant', feature_category: :service_desk do
    let_it_be(:note_metadata) { create(:note_metadata, note: note) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Persisted records required

    subject { entity.as_json[:external_author] }

    context 'with external note author' do
      let(:obfuscated_email) { 'em*****@e*****.c**' }
      let(:email) { 'email@example.com' }

      it_behaves_like 'external author'
    end
  end

  context 'when system note with issue_email_participants action', feature_category: :service_desk do
    let_it_be(:email) { 'user@example.com' }
    let_it_be(:note_text) { "added #{email}" }
    # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Notes::RenderService updates #note and #cached_markdown_version
    let_it_be(:note) { create(:note, :system, author: Users::Internal.support_bot, note: note_text) }
    let_it_be(:system_note_metadata) { create(:system_note_metadata, note: note, action: :issue_email_participants) }
    # rubocop:enable RSpec/FactoryBot/AvoidCreate

    let(:obfuscated_email) { 'us*****@e*****.c**' }
    let(:expected_text) { obfuscated_email }

    describe 'note' do
      subject { entity_hash[:note] }

      it_behaves_like 'a note content field with obfuscated email address'
    end

    describe 'note_html' do
      subject { entity_hash[:note_html] }

      it_behaves_like 'a note content field with obfuscated email address'
    end
  end
end
