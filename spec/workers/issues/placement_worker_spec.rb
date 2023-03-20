# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::PlacementWorker, feature_category: :team_planning do
  describe '#perform' do
    let_it_be(:time) { Time.now.utc }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:author) { create(:user) }
    let_it_be(:common_attrs) { { author: author, project: project } }
    let_it_be(:unplaced) { common_attrs.merge(relative_position: nil) }
    let_it_be_with_reload(:issue) { create(:issue, **unplaced, created_at: time) }
    let_it_be_with_reload(:issue_a) { create(:issue, **unplaced, created_at: time - 1.minute) }
    let_it_be_with_reload(:issue_b) { create(:issue, **unplaced, created_at: time - 2.minutes) }
    let_it_be_with_reload(:issue_c) { create(:issue, **unplaced, created_at: time + 1.minute) }
    let_it_be_with_reload(:issue_d) { create(:issue, **unplaced, created_at: time + 2.minutes) }
    let_it_be_with_reload(:issue_e) { create(:issue, **common_attrs, relative_position: 10, created_at: time + 1.minute) }
    let_it_be_with_reload(:issue_f) { create(:issue, **unplaced, created_at: time + 1.minute) }

    let_it_be(:irrelevant) { create(:issue, relative_position: nil, created_at: time) }

    shared_examples 'running the issue placement worker' do
      let(:issue_id) { issue.id }
      let(:project_id) { project.id }

      it 'places all issues created at most 5 minutes before this one at the end, most recent last' do
        expect { run_worker }.not_to change { irrelevant.reset.relative_position }

        expect(project.issues.order_by_relative_position)
          .to eq([issue_e, issue_b, issue_a, issue, issue_c, issue_f, issue_d])
        expect(project.issues.where(relative_position: nil)).not_to exist
      end

      it 'schedules rebalancing if needed' do
        issue_a.update!(relative_position: RelativePositioning::MAX_POSITION)

        expect(Issues::RebalancingWorker).to receive(:perform_async).with(nil, nil, project.group.id)

        run_worker
      end

      context 'there are more than QUERY_LIMIT unplaced issues' do
        before_all do
          # Ensure there are more than N issues in this set
          n = described_class::QUERY_LIMIT
          create_list(:issue, n - 5, **unplaced)
        end

        it 'limits the sweep to QUERY_LIMIT records, and reschedules placement' do
          expect(Issue).to receive(:move_nulls_to_end)
                             .with(have_attributes(count: described_class::QUERY_LIMIT))
                             .and_call_original

          expect(described_class).to receive(:perform_async).with(nil, project.id)

          run_worker

          expect(project.issues.where(relative_position: nil)).to exist
        end

        it 'is eventually correct' do
          prefix = project.issues.where.not(relative_position: nil).order(:relative_position).to_a
          moved = project.issues.where.not(id: prefix.map(&:id))

          run_worker

          expect(project.issues.where(relative_position: nil)).to exist

          run_worker

          expect(project.issues.where(relative_position: nil)).not_to exist
          expect(project.issues.order(:relative_position)).to eq(prefix + moved.order(:created_at, :id))
        end
      end

      context 'we are passed bad IDs' do
        let(:issue_id) { non_existing_record_id }
        let(:project_id) { non_existing_record_id }

        def max_positions_by_project
          Issue
            .group(:project_id)
            .pluck(:project_id, Issue.arel_table[:relative_position].maximum.as('max_relative_position'))
            .to_h
        end

        it 'does move any issues to the end' do
          expect { run_worker }.not_to change { max_positions_by_project }
        end

        context 'the project_id refers to an empty project' do
          let!(:project_id) { create(:project).id }

          it 'does move any issues to the end' do
            expect { run_worker }.not_to change { max_positions_by_project }
          end
        end
      end

      it 'anticipates the failure to place the issues, and schedules rebalancing' do
        allow(Issue).to receive(:move_nulls_to_end) { raise RelativePositioning::NoSpaceLeft }

        expect(Issues::RebalancingWorker).to receive(:perform_async).with(nil, nil, project.group.id)
        expect(Gitlab::ErrorTracking)
          .to receive(:log_exception)
          .with(RelativePositioning::NoSpaceLeft, worker_arguments)

        run_worker
      end
    end

    context 'passing an issue ID' do
      def run_worker
        described_class.new.perform(issue_id)
      end

      let(:worker_arguments) { { issue_id: issue_id, project_id: nil } }

      it_behaves_like 'running the issue placement worker'

      context 'when block_issue_repositioning is enabled' do
        let(:issue_id) { issue.id }
        let(:project_id) { project.id }

        before do
          stub_feature_flags(block_issue_repositioning: group)
        end

        it 'does not run repositioning tasks' do
          expect { run_worker }.not_to change { issue.reset.relative_position }
        end
      end
    end

    context 'passing a project ID' do
      def run_worker
        described_class.new.perform(nil, project_id)
      end

      let(:worker_arguments) { { issue_id: nil, project_id: project_id } }

      it_behaves_like 'running the issue placement worker'
    end
  end

  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
    expect(described_class.get_deduplication_options).to include({ including_scheduled: true })
  end
end
