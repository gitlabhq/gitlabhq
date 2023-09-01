# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Discussion, ResolvableDiscussion, feature_category: :code_review_workflow do
  subject { described_class.new([first_note, second_note, third_note]) }

  let_it_be(:first_note, reload: true) { create(:discussion_note_on_merge_request) }
  let_it_be(:noteable) { first_note.noteable }
  let_it_be(:project) { first_note.project }
  let_it_be(:second_note, reload: true) { create(:discussion_note_on_merge_request, noteable: noteable, project: project, in_reply_to: first_note) }
  let_it_be(:third_note, reload: true) { create(:discussion_note_on_merge_request, noteable: noteable, project: project) }

  let_it_be(:current_user) { create(:user) }

  describe "#resolvable?" do
    context "when potentially resolvable" do
      before do
        allow(subject).to receive(:potentially_resolvable?).and_return(true)
      end

      context "when all notes are unresolvable" do
        before do
          allow(first_note).to receive(:resolvable?).and_return(false)
          allow(second_note).to receive(:resolvable?).and_return(false)
          allow(third_note).to receive(:resolvable?).and_return(false)
        end

        it "returns false" do
          expect(subject.resolvable?).to be false
        end
      end

      context "when some notes are unresolvable and some notes are resolvable" do
        before do
          allow(first_note).to receive(:resolvable?).and_return(true)
          allow(second_note).to receive(:resolvable?).and_return(false)
          allow(third_note).to receive(:resolvable?).and_return(true)
        end

        it "returns true" do
          expect(subject.resolvable?).to be true
        end
      end

      context "when all notes are resolvable" do
        before do
          allow(first_note).to receive(:resolvable?).and_return(true)
          allow(second_note).to receive(:resolvable?).and_return(true)
          allow(third_note).to receive(:resolvable?).and_return(true)
        end

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

  describe "#resolved?" do
    context "when not resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(false)
      end

      it "returns false" do
        expect(subject.resolved?).to be false
      end
    end

    context "when resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(true)

        allow(first_note).to receive(:resolvable?).and_return(true)
        allow(second_note).to receive(:resolvable?).and_return(false)
        allow(third_note).to receive(:resolvable?).and_return(true)
      end

      context "when all resolvable notes are resolved" do
        before do
          allow(first_note).to receive(:resolved?).and_return(true)
          allow(third_note).to receive(:resolved?).and_return(true)
        end

        it "returns true" do
          expect(subject.resolved?).to be true
        end
      end

      context "when some resolvable notes are not resolved" do
        before do
          allow(first_note).to receive(:resolved?).and_return(true)
          allow(third_note).to receive(:resolved?).and_return(false)
        end

        it "returns false" do
          expect(subject.resolved?).to be false
        end
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

        allow(first_note).to receive(:resolvable?).and_return(true)
        allow(second_note).to receive(:resolvable?).and_return(false)
        allow(third_note).to receive(:resolvable?).and_return(true)
      end

      context "when all resolvable notes are resolved" do
        before do
          allow(first_note).to receive(:resolved?).and_return(true)
          allow(third_note).to receive(:resolved?).and_return(true)
        end

        it "returns false" do
          expect(subject.to_be_resolved?).to be false
        end
      end

      context "when some resolvable notes are not resolved" do
        before do
          allow(first_note).to receive(:resolved?).and_return(true)
          allow(third_note).to receive(:resolved?).and_return(false)
        end

        it "returns true" do
          expect(subject.to_be_resolved?).to be true
        end
      end
    end
  end

  describe "#can_resolve?" do
    context "when not resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(false)
      end

      it "returns false" do
        expect(subject.can_resolve?(current_user)).to be false
      end
    end

    context "when resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(true)
      end

      context "when not signed in" do
        let(:current_user) { nil }

        it "returns false" do
          expect(subject.can_resolve?(current_user)).to be false
        end
      end

      context "when signed in" do
        context "when the signed in user is the noteable author" do
          before do
            subject.noteable.author = current_user
          end

          it "returns true" do
            expect(subject.can_resolve?(current_user)).to be true
          end

          context 'when noteable is locked' do
            before do
              allow(subject.noteable).to receive(:discussion_locked?).and_return(true)
            end

            it 'returns false' do
              expect(subject.can_resolve?(current_user)).to be_falsey
            end
          end
        end

        context "when the signed in user can push to the project" do
          before_all do
            project.add_maintainer(current_user)
          end

          it "returns true" do
            expect(subject.can_resolve?(current_user)).to be true
          end

          context "when the noteable has no author" do
            before do
              noteable.author = nil
            end

            it "returns true" do
              expect(subject.can_resolve?(current_user)).to be true
            end
          end
        end

        context "when the signed in user is a random user" do
          it "returns false" do
            expect(subject.can_resolve?(current_user)).to be false
          end

          context "when the noteable has no author" do
            before do
              subject.noteable.author = nil
            end

            it "returns false" do
              expect(subject.can_resolve?(current_user)).to be false
            end
          end
        end
      end
    end
  end

  describe "#resolve!" do
    context "when not resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(false)
      end

      it "returns nil" do
        expect(subject.resolve!(current_user)).to be_nil
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
      let_it_be(:user) { create(:user) }
      let_it_be(:second_note) { create(:diff_note_on_commit) } # unresolvable

      before do
        allow(subject).to receive(:resolvable?).and_return(true)
      end

      context "when all resolvable notes are resolved" do
        before do
          first_note.resolve!(user)
          third_note.resolve!(user)

          first_note.reload
          third_note.reload
        end

        it "doesn't change resolved_at on the resolved notes" do
          expect(first_note.resolved_at).not_to be_nil
          expect(third_note.resolved_at).not_to be_nil

          expect { subject.resolve!(current_user) }.not_to change { first_note.resolved_at }
          expect { subject.resolve!(current_user) }.not_to change { third_note.resolved_at }
        end

        it "doesn't change resolved_by on the resolved notes" do
          expect(first_note.resolved_by).to eq(user)
          expect(third_note.resolved_by).to eq(user)

          expect { subject.resolve!(current_user) }.not_to change { first_note.resolved_by }
          expect { subject.resolve!(current_user) }.not_to change { third_note.resolved_by }
        end

        it "doesn't change the resolved state on the resolved notes" do
          expect(first_note.resolved?).to be true
          expect(third_note.resolved?).to be true

          expect { subject.resolve!(current_user) }.not_to change { first_note.resolved? }
          expect { subject.resolve!(current_user) }.not_to change { third_note.resolved? }
        end

        it "doesn't change resolved_at" do
          expect(subject.resolved_at).not_to be_nil

          expect { subject.resolve!(current_user) }.not_to change { subject.resolved_at }
        end

        it "doesn't change resolved_by" do
          expect(subject.resolved_by).to eq(user)

          expect { subject.resolve!(current_user) }.not_to change { subject.resolved_by }
        end

        it "doesn't change resolved state" do
          expect(subject.resolved?).to be true

          expect { subject.resolve!(current_user) }.not_to change { subject.resolved? }
        end
      end

      context "when some resolvable notes are resolved" do
        before do
          first_note.resolve!(user)
        end

        it "doesn't change resolved_at on the resolved note" do
          expect(first_note.resolved_at).not_to be_nil

          expect { subject.resolve!(current_user) }
            .not_to change { first_note.reload.resolved_at }
        end

        it "doesn't change resolved_by on the resolved note" do
          expect(first_note.resolved_by).to eq(user)

          expect { subject.resolve!(current_user) }
            .not_to change { first_note.reload && first_note.resolved_by }
        end

        it "doesn't change the resolved state on the resolved note" do
          expect(first_note.resolved?).to be true

          expect { subject.resolve!(current_user) }
            .not_to change { first_note.reload && first_note.resolved? }
        end

        it "sets resolved_at on the unresolved note" do
          subject.resolve!(current_user)
          third_note.reload

          expect(third_note.resolved_at).not_to be_nil
        end

        it "sets resolved_by on the unresolved note" do
          subject.resolve!(current_user)
          third_note.reload

          expect(third_note.resolved_by).to eq(current_user)
        end

        it "marks the unresolved note as resolved" do
          subject.resolve!(current_user)
          third_note.reload

          expect(third_note.resolved?).to be true
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
      end

      context "when no resolvable notes are resolved" do
        it "sets resolved_at on the unresolved notes" do
          subject.resolve!(current_user)
          first_note.reload
          third_note.reload

          expect(first_note.resolved_at).not_to be_nil
          expect(third_note.resolved_at).not_to be_nil
        end

        it "sets resolved_by on the unresolved notes" do
          subject.resolve!(current_user)
          first_note.reload
          third_note.reload

          expect(first_note.resolved_by).to eq(current_user)
          expect(third_note.resolved_by).to eq(current_user)
        end

        it "marks the unresolved notes as resolved" do
          subject.resolve!(current_user)
          first_note.reload
          third_note.reload

          expect(first_note.resolved?).to be true
          expect(third_note.resolved?).to be true
        end

        it "sets resolved_at" do
          subject.resolve!(current_user)
          first_note.reload
          third_note.reload

          expect(subject.resolved_at).not_to be_nil
        end

        it "sets resolved_by" do
          subject.resolve!(current_user)
          first_note.reload
          third_note.reload

          expect(subject.resolved_by).to eq(current_user)
        end

        it "marks as resolved" do
          subject.resolve!(current_user)
          first_note.reload
          third_note.reload

          expect(subject.resolved?).to be true
        end

        it "broadcasts note change of the noteable" do
          expect(subject.noteable).to receive(:broadcast_notes_changed)

          subject.resolve!(current_user)
        end
      end
    end
  end

  describe "#unresolve!" do
    context "when not resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(false)
      end

      it "returns nil" do
        expect(subject.unresolve!).to be_nil
      end
    end

    context "when resolvable" do
      let_it_be(:user) { create(:user) }

      before do
        allow(subject).to receive(:resolvable?).and_return(true)

        allow(first_note).to receive(:resolvable?).and_return(true)
        allow(second_note).to receive(:resolvable?).and_return(false)
        allow(third_note).to receive(:resolvable?).and_return(true)
      end

      context "when all resolvable notes are resolved" do
        before do
          first_note.resolve!(user)
          third_note.resolve!(user)
        end

        it "unsets resolved_at on the resolved notes" do
          subject.unresolve!
          first_note.reload
          third_note.reload

          expect(first_note.resolved_at).to be_nil
          expect(third_note.resolved_at).to be_nil
        end

        it "unsets resolved_by on the resolved notes" do
          subject.unresolve!
          first_note.reload
          third_note.reload

          expect(first_note.resolved_by).to be_nil
          expect(third_note.resolved_by).to be_nil
        end

        it "unmarks the resolved notes as resolved" do
          subject.unresolve!
          first_note.reload
          third_note.reload

          expect(first_note.resolved?).to be false
          expect(third_note.resolved?).to be false
        end

        it "unsets resolved_at" do
          subject.unresolve!
          first_note.reload
          third_note.reload

          expect(subject.resolved_at).to be_nil
        end

        it "unsets resolved_by" do
          subject.unresolve!
          first_note.reload
          third_note.reload

          expect(subject.resolved_by).to be_nil
        end

        it "unmarks as resolved" do
          subject.unresolve!

          expect(subject.resolved?).to be false
        end

        it "broadcasts note change of the noteable" do
          expect(subject.noteable).to receive(:broadcast_notes_changed)

          subject.unresolve!
        end
      end

      context "when some resolvable notes are resolved" do
        before do
          first_note.resolve!(user)
        end

        it "unsets resolved_at on the resolved note" do
          subject.unresolve!

          expect(subject.first_note.resolved_at).to be_nil
        end

        it "unsets resolved_by on the resolved note" do
          subject.unresolve!

          expect(subject.first_note.resolved_by).to be_nil
        end

        it "unmarks the resolved note as resolved" do
          subject.unresolve!

          expect(subject.first_note.resolved?).to be false
        end
      end
    end
  end

  describe "#first_note_to_resolve" do
    it "returns the first note that still needs to be resolved" do
      allow(first_note).to receive(:to_be_resolved?).and_return(false)
      allow(second_note).to receive(:to_be_resolved?).and_return(true)

      expect(subject.first_note_to_resolve).to eq(second_note)
    end
  end

  describe "#last_resolved_note" do
    let(:time) { Time.current.utc }

    before do
      travel_to(time - 1.second) do
        first_note.resolve!(current_user)
      end
      travel_to(time) do
        third_note.resolve!(current_user)
      end
      travel_to(time + 1.second) do
        second_note.resolve!(current_user)
      end
    end

    it "returns the last note that was resolved" do
      expect(subject.last_resolved_note).to eq(second_note)
    end
  end

  describe '#clear_memoized_values' do
    it 'resets the memoized values' do
      described_class.memoized_values.each do |memo|
        subject.instance_variable_set("@#{memo}", 'memoized')
        expect { subject.clear_memoized_values }.to change { subject.instance_variable_get("@#{memo}") }
          .from('memoized').to(nil)
      end
    end
  end
end
