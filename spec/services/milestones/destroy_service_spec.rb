# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Milestones::DestroyService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, maintainers: user) }
  let_it_be(:project) { create(:project, :repository, group: group) }

  subject(:service) { described_class.new(container, user, {}) }

  describe '#execute' do
    shared_examples 'deletes milestone id from issuables' do
      specify do
        stub_const('Milestones::DestroyService::BATCH_SIZE', 2)

        issues = create_list(:issue, described_class::BATCH_SIZE + 1, project: project, milestone: milestone)
        merge_request = create(:merge_request, source_project: project, milestone: milestone)

        expect(milestone).to receive(:run_after_commit).and_yield

        expect { expect(service.execute(milestone)).to eq(milestone) }
          .to publish_event(WorkItems::BulkUpdatedEvent)
          .with(
            root_namespace_id: group.id,
            work_item_ids: issues.take(described_class::BATCH_SIZE).map(&:id),
            updated_attributes: %w[milestone_id]
          )

        milestone.reload
        issues.each do |issue|
          expect(issue.reload.milestone).to be_nil
        end
        expect(merge_request.reload.milestone).to be_nil
      end
    end

    context 'on project milestones' do
      let_it_be_with_reload(:milestone) { create(:milestone, title: 'Milestone v1.0', project: project) }

      let(:container) { project }

      it 'deletes milestone' do
        service.execute(milestone)

        expect { milestone.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it_behaves_like 'deletes milestone id from issuables'

      it 'logs destroy event' do
        service.execute(milestone)

        event = Event.where(project_id: milestone.project_id, target_type: 'Milestone')

        expect(event.count).to eq(1)
      end

      context 'when a release is tied to a milestone' do
        it 'destroys the milestone but not the associated release' do
          release = create(
            :release,
            tag: 'v1.0',
            project: project,
            milestones: [milestone]
          )

          expect { service.execute(milestone) }.not_to change { Release.count }
          expect(release.reload).to be_persisted
        end
      end
    end

    context 'on group milestones' do
      let_it_be_with_reload(:milestone) { create(:milestone, group: group) }

      let(:container) { group }

      it 'deletes milestone' do
        service.execute(milestone)

        expect { milestone.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it_behaves_like 'deletes milestone id from issuables'

      it 'does not log destroy event' do
        expect { service.execute(milestone) }.not_to change { Event.count }
      end
    end
  end
end
