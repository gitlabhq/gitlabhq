# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::CleanupRefsService do
  describe '.schedule' do
    let(:merge_request) { create(:merge_request) }

    it 'creates a merge request cleanup schedule' do
      freeze_time do
        described_class.schedule(merge_request)

        expect(merge_request.reload.cleanup_schedule.scheduled_at)
          .to eq(described_class::TIME_THRESHOLD.from_now)
      end
    end
  end

  describe '#execute' do
    before do
      # Need to re-enable this as it's being stubbed in spec_helper for
      # performance reasons but is needed to run for this test.
      allow(Gitlab::Git::KeepAround).to receive(:execute).and_call_original

      merge_request.create_cleanup_schedule(scheduled_at: described_class::TIME_THRESHOLD.ago)
    end

    subject(:result) { described_class.new(merge_request).execute }

    shared_examples_for 'service that cleans up merge request refs' do
      it 'creates keep around ref and deletes merge request refs' do
        old_ref_head = ref_head

        aggregate_failures do
          expect(result[:status]).to eq(:success)
          expect(kept_around?(old_ref_head)).to be_truthy
          expect(ref_head).to be_nil
          expect(merge_request.cleanup_schedule.completed_at).to be_present
        end
      end

      context 'when merge request has no head ref' do
        before do
          # Simulate a merge request with no head ref
          merge_request.project.repository.delete_refs(merge_request.ref_path)
        end

        it 'does not fail' do
          expect(result[:status]).to eq(:success)
          expect(merge_request.cleanup_schedule.completed_at).to be_present
        end
      end

      context 'when merge request has merge ref' do
        before do
          MergeRequests::MergeToRefService
            .new(project: merge_request.project, current_user: merge_request.author)
            .execute(merge_request)
        end

        it 'caches merge ref sha and deletes merge ref' do
          old_merge_ref_head = merge_request.merge_ref_head

          aggregate_failures do
            expect(result[:status]).to eq(:success)
            expect(kept_around?(old_merge_ref_head)).to be_truthy
            expect(merge_request.reload.merge_ref_sha).to eq(old_merge_ref_head.id)
            expect(ref_exists?(merge_request.merge_ref_path)).to be_falsy
          end
        end

        context 'when merge ref sha cannot be cached' do
          before do
            allow(merge_request)
              .to receive(:update_column)
              .with(:merge_ref_sha, merge_request.merge_ref_head.id)
              .and_return(false)
          end

          it_behaves_like 'service that does not clean up merge request refs'
        end
      end

      context 'when keep around ref cannot be created' do
        before do
          allow_next_instance_of(Gitlab::Git::KeepAround) do |keep_around|
            expect(keep_around).to receive(:kept_around?).and_return(false)
          end
        end

        it_behaves_like 'service that does not clean up merge request refs'
      end

      context 'when a git error is raised' do
        context 'Gitlab::Git::Repository::GitError' do
          before do
            allow(merge_request.project.repository).to receive(:delete_refs).and_raise(Gitlab::Git::Repository::GitError)
          end

          it_behaves_like 'service that does not clean up merge request refs'
        end

        context 'Gitlab::Git::CommandError' do
          before do
            allow_next_instance_of(Gitlab::Git::KeepAround) do |keep_around|
              expect(keep_around).to receive(:kept_around?).and_raise(Gitlab::Git::CommandError)
            end
          end

          it_behaves_like 'service that does not clean up merge request refs'
        end
      end

      context 'when cleanup schedule fails to update' do
        before do
          allow(merge_request.cleanup_schedule).to receive(:update).and_return(false)
        end

        it 'creates keep around ref and deletes merge request refs' do
          old_ref_head = ref_head

          aggregate_failures do
            expect(result[:status]).to eq(:error)
            expect(kept_around?(old_ref_head)).to be_truthy
            expect(ref_head).to be_nil
            expect(merge_request.cleanup_schedule.completed_at).not_to be_present
          end
        end
      end

      context 'when merge request is not scheduled to be cleaned up yet' do
        before do
          merge_request.cleanup_schedule.update!(scheduled_at: 1.day.from_now)
        end

        it_behaves_like 'service that does not clean up merge request refs'
      end

      context 'when repository no longer exists' do
        before do
          Repositories::DestroyService.new(merge_request.project.repository).execute
        end

        it 'does not fail and still mark schedule as complete' do
          aggregate_failures do
            expect(result[:status]).to eq(:success)
            expect(merge_request.cleanup_schedule.completed_at).to be_present
          end
        end
      end
    end

    shared_examples_for 'service that does not clean up merge request refs' do
      it 'does not delete merge request refs' do
        aggregate_failures do
          expect(result[:status]).to eq(:error)
          expect(ref_head).to be_present
          expect(merge_request.cleanup_schedule.completed_at).not_to be_present
        end
      end
    end

    context 'when merge request is closed' do
      let(:merge_request) { create(:merge_request, :closed) }

      context "when closed #{described_class::TIME_THRESHOLD.inspect} ago" do
        before do
          merge_request.metrics.update!(latest_closed_at: described_class::TIME_THRESHOLD.ago)
        end

        it_behaves_like 'service that cleans up merge request refs'
      end

      context "when closed later than #{described_class::TIME_THRESHOLD.inspect} ago" do
        before do
          merge_request.metrics.update!(latest_closed_at: (described_class::TIME_THRESHOLD - 1.day).ago)
        end

        it_behaves_like 'service that does not clean up merge request refs'
      end
    end

    context 'when merge request is merged' do
      let(:merge_request) { create(:merge_request, :merged) }

      context "when merged #{described_class::TIME_THRESHOLD.inspect} ago" do
        before do
          merge_request.metrics.update!(merged_at: described_class::TIME_THRESHOLD.ago)
        end

        it_behaves_like 'service that cleans up merge request refs'
      end

      context "when merged later than #{described_class::TIME_THRESHOLD.inspect} ago" do
        before do
          merge_request.metrics.update!(merged_at: (described_class::TIME_THRESHOLD - 1.day).ago)
        end

        it_behaves_like 'service that does not clean up merge request refs'
      end
    end

    context 'when merge request is not closed nor merged' do
      let(:merge_request) { create(:merge_request, :opened) }

      it_behaves_like 'service that does not clean up merge request refs'
    end
  end

  def kept_around?(commit)
    Gitlab::Git::KeepAround.new(merge_request.project.repository).kept_around?(commit.id)
  end

  def ref_head
    merge_request.project.repository.commit(merge_request.ref_path)
  end

  def ref_exists?(ref)
    merge_request.project.repository.ref_exists?(ref)
  end
end
