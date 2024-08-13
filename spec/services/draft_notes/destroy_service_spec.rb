# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DraftNotes::DestroyService, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.target_project }
  let(:user) { merge_request.author }

  def destroy(draft_note = nil)
    DraftNotes::DestroyService.new(merge_request, user).execute(draft_note)
  end

  it 'destroys a single draft note' do
    drafts = create_list(:draft_note, 2, merge_request: merge_request, author: user)

    expect { destroy(drafts.first) }
      .to change { DraftNote.count }.by(-1)

    expect(DraftNote.count).to eq(1)
  end

  it 'destroys all draft notes for a user in a merge request' do
    create_list(:draft_note, 2, merge_request: merge_request, author: user)

    expect { destroy }.to change { DraftNote.count }.by(-2) # rubocop:disable Rails/SaveBang
    expect(DraftNote.count).to eq(0)
  end

  it 'updates reviewer state when all draft notes are deleted' do
    draft = create(:draft_note, merge_request: merge_request, author: user)

    expect_next_instance_of(
      MergeRequests::UpdateReviewerStateService,
      project: project, current_user: user
    ) do |service|
      expect(service).to receive(:execute).with(merge_request, 'unreviewed')
    end

    destroy(draft)
  end

  context 'diff highlight cache clearing' do
    context 'when destroying all draft notes of a user' do
      it 'clears highlighting cache if unfold required for any' do
        drafts = create_list(:draft_note, 2, merge_request: merge_request, author: user)

        allow_any_instance_of(DraftNote).to receive_message_chain(:diff_file, :unfolded?) { true }
        expect(merge_request).to receive_message_chain(:diffs, :clear_cache)

        destroy(drafts.first)
      end
    end

    context 'when destroying one draft note' do
      it 'clears highlighting cache if unfold required' do
        create_list(:draft_note, 2, merge_request: merge_request, author: user)

        allow_any_instance_of(DraftNote).to receive_message_chain(:diff_file, :unfolded?) { true }
        expect(merge_request).to receive_message_chain(:diffs, :clear_cache)

        destroy # rubocop:disable Rails/SaveBang
      end
    end
  end
end
