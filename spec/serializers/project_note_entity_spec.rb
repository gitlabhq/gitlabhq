# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectNoteEntity do
  include Gitlab::Routing

  let_it_be(:note) { create(:note_on_merge_request) }
  let_it_be(:user) { create(:user) }

  let(:request) { double('request', current_user: user, noteable: note.noteable) }
  let(:entity) { described_class.new(note, request: request) }

  subject { entity.as_json }

  it_behaves_like 'note entity'

  it 'exposes project-specific elements' do
    expect(subject).to include(:human_access, :toggle_award_path, :path)
  end

  context 'when note is part of resolvable discussion' do
    before do
      allow(note).to receive(:part_of_discussion?).and_return(true)
      allow(note).to receive(:resolvable?).and_return(true)
    end

    it 'exposes paths to resolve note' do
      expect(subject).to include(:resolve_path, :resolve_with_issue_path)
    end

    context 'when note is on an issue' do
      let(:note) { create(:note_on_issue) }

      it 'does not include resolve_with_issue_path' do
        expect(subject).not_to include(:resolve_with_issue_path)
      end
    end
  end
end
