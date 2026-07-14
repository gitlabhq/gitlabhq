# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DraftNoteEntity, feature_category: :code_review_workflow do
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:merge_request) { build_stubbed(:merge_request) }

  let(:draft_note) { build(:draft_note, merge_request: merge_request, author: user) }
  let(:request) { double('EntityRequest', current_user: user) } # rubocop:disable RSpec/VerifiedDoubles -- EntityRequest uses define_singleton_method so methods cannot be verified
  let(:entity) { described_class.new(draft_note, request: request) }

  subject(:json) { entity.as_json }

  it 'exposes correct attributes' do
    expect(json.keys).to contain_exactly(
      :id,
      :author,
      :merge_request_id,
      :commit_id,
      :line_code,
      :file_identifier_hash,
      :file_hash,
      :file_path,
      :note,
      :note_html,
      :references,
      :suggestions,
      :discussion_id,
      :resolve_discussion,
      :noteable_type,
      :internal,
      :current_user
    )
  end

  it 'exposes author using NoteUserEntity' do
    expect(json[:author].keys).to include(:id, :name, :username)
  end

  describe 'position exposure' do
    context 'when draft note is on a diff' do
      before do
        allow(draft_note).to receive(:on_diff?).and_return(true)
      end

      it 'exposes position and original_position' do
        expect(json.keys).to include(:position, :original_position)
      end
    end

    context 'when draft note is not on a diff' do
      it 'does not expose position or original_position' do
        expect(json.keys).not_to include(:position, :original_position)
      end
    end
  end

  describe 'current_user' do
    subject(:current_user_json) { json[:current_user] }

    it 'exposes can_edit, can_award_emoji, and can_resolve' do
      expect(current_user_json.keys).to contain_exactly(:can_edit, :can_award_emoji, :can_resolve)
    end

    describe 'can_edit' do
      it 'is true when the current user can admin the note' do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :admin_note, draft_note).and_return(true)

        expect(current_user_json[:can_edit]).to be(true)
      end

      it 'is false when the current user cannot admin the note' do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :admin_note, draft_note).and_return(false)

        expect(current_user_json[:can_edit]).to be(false)
      end
    end

    describe 'can_award_emoji' do
      it 'is true when the draft note is emoji awardable' do
        allow(draft_note).to receive(:emoji_awardable?).and_return(true)

        expect(current_user_json[:can_award_emoji]).to be(true)
      end

      it 'is false when the draft note is not emoji awardable' do
        allow(draft_note).to receive(:emoji_awardable?).and_return(false)

        expect(current_user_json[:can_award_emoji]).to be(false)
      end
    end

    describe 'can_resolve' do
      it 'is false when the draft note is not resolvable' do
        allow(draft_note).to receive(:resolvable?).and_return(false)

        expect(current_user_json[:can_resolve]).to be(false)
      end

      context 'when the draft note is resolvable' do
        before do
          allow(draft_note).to receive(:resolvable?).and_return(true)
          allow(Ability).to receive(:allowed?).and_call_original
        end

        it 'is true when the current user can resolve the note' do
          allow(Ability).to receive(:allowed?).with(user, :resolve_note, draft_note).and_return(true)

          expect(current_user_json[:can_resolve]).to be(true)
        end

        it 'is false when the current user cannot resolve the note' do
          allow(Ability).to receive(:allowed?).with(user, :resolve_note, draft_note).and_return(false)

          expect(current_user_json[:can_resolve]).to be(false)
        end
      end
    end
  end
end
