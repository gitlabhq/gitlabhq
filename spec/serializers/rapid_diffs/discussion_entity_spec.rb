# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/FactoryBot/AvoidCreate -- Need database access
RSpec.describe RapidDiffs::DiscussionEntity, feature_category: :code_review_workflow do
  include RepoHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  let(:request) { double('request', current_user: user, noteable: merge_request) } # rubocop:disable RSpec/VerifiedDoubles -- EntityRequest uses define_singleton_method
  let(:entity) { described_class.new(discussion, request: request) }

  subject(:serialized_discussion) { entity.as_json }

  describe 'basic attributes' do
    let(:discussion) do
      create(:discussion_note_on_merge_request, project: project, noteable: merge_request).to_discussion
    end

    it 'exposes basic discussion attributes' do
      expect(serialized_discussion).to include(
        id: discussion.id,
        reply_id: discussion.reply_id,
        confidential: discussion.confidential?,
        diff_discussion: discussion.diff_discussion?
      )
    end

    it 'includes notes' do
      expect(serialized_discussion).to have_key(:notes)
      expect(serialized_discussion[:notes]).to be_an(Array)
    end

    it 'delegates notes serialization to RapidDiffs::NoteEntity' do
      allow(RapidDiffs::NoteEntity).to receive(:represent).and_call_original

      serialized_discussion

      expect(RapidDiffs::NoteEntity).to have_received(:represent).with(
        discussion.notes,
        hash_including(
          with_base_discussion: false,
          discussion: discussion
        )
      )
    end
  end

  describe 'confidential attribute' do
    context 'when discussion is confidential' do
      let(:discussion) do
        create(:discussion_note_on_merge_request, :confidential, project: project,
          noteable: merge_request).to_discussion
      end

      it 'exposes confidential as true' do
        expect(serialized_discussion[:confidential]).to be true
      end
    end

    context 'when discussion is not confidential' do
      let(:discussion) do
        create(:discussion_note_on_merge_request, project: project, noteable: merge_request).to_discussion
      end

      it 'exposes confidential as false' do
        expect(serialized_discussion[:confidential]).to be false
      end
    end
  end

  describe 'position attribute' do
    context 'when discussion is a diff discussion' do
      let(:discussion) do
        create(:diff_note_on_merge_request, project: project, noteable: merge_request).to_discussion
      end

      it 'exposes diff_discussion as true' do
        expect(serialized_discussion[:diff_discussion]).to be true
      end

      it 'includes position for non-legacy diff discussions' do
        expect(serialized_discussion).to have_key(:position)
        expect(serialized_discussion[:position]).to eq(discussion.position)
      end
    end

    context 'when discussion is a legacy diff discussion' do
      let(:discussion) do
        create(:legacy_diff_note_on_merge_request, project: project, noteable: merge_request).to_discussion
      end

      it 'does not include position' do
        expect(serialized_discussion).not_to have_key(:position)
      end
    end

    context 'when discussion is not a diff discussion' do
      let(:discussion) do
        create(:discussion_note_on_merge_request, project: project, noteable: merge_request).to_discussion
      end

      it 'exposes diff_discussion as false' do
        expect(serialized_discussion[:diff_discussion]).to be false
      end

      it 'does not include position' do
        expect(serialized_discussion).not_to have_key(:position)
      end
    end
  end
end
# rubocop:enable RSpec/FactoryBot/AvoidCreate -- Need database access
