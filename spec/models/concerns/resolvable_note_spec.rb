# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Note, ResolvableNote, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  subject { create(:discussion_note_on_merge_request, noteable: merge_request, project: project) }

  context 'resolvability scopes' do
    let_it_be(:note1) { create(:note, project: project) }
    let_it_be(:note2) { create(:diff_note_on_commit, project: project) }
    let_it_be(:note3) { create(:diff_note_on_merge_request, :resolved, noteable: merge_request, project: project) }
    let_it_be(:note4) { create(:discussion_note_on_merge_request, noteable: merge_request, project: project) }
    let_it_be(:note5) { create(:discussion_note_on_issue, project: project) }
    let_it_be(:note6) { create(:discussion_note_on_merge_request, :system, noteable: merge_request, project: project) }
    let_it_be(:note7) { create(:discussion_note_on_issue, :resolved, project: project) }

    describe '.potentially_resolvable' do
      it 'includes diff and discussion notes on issues and merge requests' do
        expect(described_class.potentially_resolvable).to match_array([note3, note4, note5, note6, note7])
      end
    end

    describe '.resolvable' do
      it 'includes non-system diff and discussion notes on issues and merge requests' do
        expect(described_class.resolvable).to match_array([note3, note4, note5, note7])
      end
    end

    describe '.resolved' do
      it 'includes resolved non-system diff and discussion notes on issues and merge requests' do
        expect(described_class.resolved).to match_array([note3, note7])
      end
    end

    describe '.unresolved' do
      it 'includes non-resolved non-system diff and discussion notes on issues and merge requests' do
        expect(described_class.unresolved).to match_array([note4, note5])
      end
    end
  end

  describe '.resolvable_types' do
    specify do
      types = described_class::RESOLVABLE_TYPES
      types += EE::ResolvableNote::EE_RESOLVABLE_TYPES if Gitlab.ee?

      expect(described_class.resolvable_types).to eq(types)
    end
  end

  describe ".resolve!" do
    let(:current_user) { create(:user) }
    let!(:commit_note) { create(:diff_note_on_commit, project: project) }
    let!(:resolved_note) { create(:discussion_note_on_merge_request, :resolved, noteable: merge_request, project: project) }
    let!(:unresolved_note) { create(:discussion_note_on_merge_request, noteable: merge_request, project: project) }

    before do
      described_class.resolve!(current_user)

      commit_note.reload
      resolved_note.reload
      unresolved_note.reload
    end

    it 'resolves only the resolvable, not yet resolved notes', :freeze_time do
      expect(commit_note.resolved_at).to be_nil
      expect(resolved_note.resolved_by).not_to eq(current_user)

      expect(unresolved_note.resolved_at).not_to be_nil
      expect(unresolved_note.resolved_by).to eq(current_user)
      expect(unresolved_note.updated_at).to be_like_time(Time.current)
    end
  end

  describe ".unresolve!" do
    let!(:resolved_note) { create(:discussion_note_on_merge_request, :resolved, noteable: merge_request, project: project) }

    before do
      described_class.unresolve!

      resolved_note.reload
    end

    it 'unresolves the resolved notes', :freeze_time do
      expect(resolved_note.resolved_by).to be_nil
      expect(resolved_note.resolved_at).to be_nil
      expect(resolved_note.updated_at).to be_like_time(Time.current)
    end
  end

  describe '#resolvable?' do
    context "when potentially resolvable" do
      before do
        allow(subject).to receive(:potentially_resolvable?).and_return(true)
      end

      context "when a system note" do
        before do
          subject.system = true
        end

        it "returns false" do
          expect(subject.resolvable?).to be false
        end
      end

      context "when a regular note" do
        it "returns true" do
          expect(subject.resolvable?).to be true
        end
      end
    end

    context "when not potentially resolvable" do
      before do
        allow(subject).to receive(:potentially_resolvable?).and_return(false)
      end

      it "returns false" do
        expect(subject.resolvable?).to be false
      end
    end
  end

  describe "#to_be_resolved?" do
    context "when not resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(false)
      end

      it "returns false" do
        expect(subject.to_be_resolved?).to be false
      end
    end

    context "when resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(true)
      end

      context "when resolved" do
        before do
          allow(subject).to receive(:resolved?).and_return(true)
        end

        it "returns false" do
          expect(subject.to_be_resolved?).to be false
        end
      end

      context "when not resolved" do
        before do
          allow(subject).to receive(:resolved?).and_return(false)
        end

        it "returns true" do
          expect(subject.to_be_resolved?).to be true
        end
      end
    end
  end

  describe "#resolved?" do
    let(:current_user) { create(:user) }

    context 'when not resolvable' do
      before do
        subject.resolve!(current_user)

        allow(subject).to receive(:resolvable?).and_return(false)
      end

      it 'returns false' do
        expect(subject.resolved?).to be_falsey
      end
    end

    context 'when resolvable' do
      context 'when the note has been resolved' do
        before do
          subject.resolve!(current_user)
        end

        it 'returns true' do
          expect(subject.resolved?).to be_truthy
        end
      end

      context 'when the note has not been resolved' do
        it 'returns false' do
          expect(subject.resolved?).to be_falsey
        end
      end
    end
  end

  describe "#resolve!" do
    let(:current_user) { create(:user) }

    context "when not resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(false)
      end

      it "returns false" do
        expect(subject.resolve!(current_user)).to be_falsey
      end

      it "doesn't set resolved_at" do
        subject.resolve!(current_user)

        expect(subject.resolved_at).to be_nil
      end

      it "doesn't set resolved_by" do
        subject.resolve!(current_user)

        expect(subject.resolved_by).to be_nil
      end

      it "doesn't mark as resolved" do
        subject.resolve!(current_user)

        expect(subject.resolved?).to be false
      end
    end

    context "when resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(true)
      end

      context "when already resolved" do
        let(:user) { create(:user) }

        before do
          subject.resolve!(user)
        end

        it "returns false" do
          expect(subject.resolve!(current_user)).to be_falsey
        end

        it "doesn't change resolved_at" do
          expect(subject.resolved_at).not_to be_nil

          expect { subject.resolve!(current_user) }.not_to change { subject.resolved_at }
        end

        it "doesn't change resolved_by" do
          expect(subject.resolved_by).to eq(user)

          expect { subject.resolve!(current_user) }.not_to change { subject.resolved_by }
        end

        it "doesn't change resolved status" do
          expect(subject.resolved?).to be true

          expect { subject.resolve!(current_user) }.not_to change { subject.resolved? }
        end
      end

      context "when not yet resolved" do
        it "returns true" do
          expect(subject.resolve!(current_user)).to be true
        end

        it "sets resolved_at" do
          subject.resolve!(current_user)

          expect(subject.resolved_at).not_to be_nil
        end

        it "sets resolved_by" do
          subject.resolve!(current_user)

          expect(subject.resolved_by).to eq(current_user)
        end

        it "marks as resolved" do
          subject.resolve!(current_user)

          expect(subject.resolved?).to be true
        end

        it "updates the updated_at timestamp", :freeze_time do
          subject.resolve!(current_user)

          expect(subject.updated_at).to be_like_time(Time.current)
        end
      end
    end
  end

  describe "#unresolve!" do
    context "when not resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(false)
      end

      it "returns false" do
        expect(subject.unresolve!).to be_falsey
      end
    end

    context "when resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(true)
      end

      context "when resolved" do
        let(:user) { create(:user) }

        before do
          subject.resolve!(user)
        end

        it "returns true" do
          expect(subject.unresolve!).to be true
        end

        it "unsets resolved_at" do
          subject.unresolve!

          expect(subject.resolved_at).to be_nil
        end

        it "unsets resolved_by" do
          subject.unresolve!

          expect(subject.resolved_by).to be_nil
        end

        it "unmarks as resolved" do
          subject.unresolve!

          expect(subject.resolved?).to be false
        end

        it "updates the updated_at timestamp", :freeze_time do
          subject.unresolve!

          expect(subject.updated_at).to be_like_time(Time.current)
        end
      end

      context "when not resolved" do
        it "returns false" do
          expect(subject.unresolve!).to be_falsey
        end
      end
    end
  end

  describe "#potentially_resolvable?" do
    it 'returns false if noteable could not be found' do
      allow(subject).to receive(:noteable).and_return(nil)

      expect(subject.potentially_resolvable?).to be_falsey
    end
  end
end
