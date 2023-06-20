# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NoteEntity do
  include Gitlab::Routing

  let(:request) { double('request', current_user: user, noteable: note.noteable) }

  let(:entity) { described_class.new(note, request: request) }
  let(:note) { create(:note) }
  let(:user) { create(:user) }

  subject { entity.as_json }

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

  describe 'with email participant' do
    let_it_be(:note) { create(:note) }
    let_it_be(:note_metadata) { create(:note_metadata, note: note) }

    subject { entity.as_json[:external_author] }

    context 'with external note author' do
      let(:obfuscated_email) { 'em*****@e*****.c**' }
      let(:email) { 'email@example.com' }

      it_behaves_like 'external author'
    end
  end
end
