# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::DeleteGroupPagesDeploymentsWorker, feature_category: :pages do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project_1) { create(:project, group: group) }
  let_it_be(:project_2) { create(:project, group: group) }
  let_it_be(:project_3) { create(:project, group: subgroup) }
  let_it_be(:project_without_pages) { create(:project, group: group) }

  let!(:pages_deployment_1) { create(:pages_deployment, project: project_1) }
  let!(:pages_deployment_2) { create(:pages_deployment, project: project_2) }
  let!(:pages_deployment_3) { create(:pages_deployment, project: project_3) }

  let(:event) do
    ::Namespaces::Groups::GroupArchivedEvent.new(data: {
      group_id: group.id,
      root_namespace_id: group.id
    })
  end

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :always
  it_behaves_like 'subscribes to event'

  subject(:use_event) { consume_event(subscriber: described_class, event: event) }

  describe '#handle_event' do
    context 'when group has multiple projects with pages' do
      it 'calls Pages::DeleteService for each project with pages', :aggregate_failures do
        expect(Pages::DeleteService).to receive(:new).with(project_1, project_1.owner).and_call_original
        expect(Pages::DeleteService).to receive(:new).with(project_2, project_2.owner).and_call_original
        expect(Pages::DeleteService).to receive(:new).with(project_3, project_3.owner).and_call_original
        expect(Pages::DeleteService).not_to receive(:new).with(project_without_pages, anything)

        use_event
      end

      it 'marks pages as not deployed for all projects', :sidekiq_inline do
        project_1.update!(archived: true)
        project_2.update!(archived: true)
        project_3.update!(archived: true)

        expect { use_event }
          .to change { project_1.reload.pages_deployed? }.from(true).to(false)
          .and change { project_2.reload.pages_deployed? }.from(true).to(false)
          .and change { project_3.reload.pages_deployed? }.from(true).to(false)
      end

      it 'removes pages deployments for all projects in the group and subgroups', :sidekiq_inline do
        project_1.update!(archived: true)
        project_2.update!(archived: true)
        project_3.update!(archived: true)

        expect { use_event }
          .to change { PagesDeployment.count }.by(-3)
      end
    end

    context 'when group does not exist' do
      let(:event) do
        ::Namespaces::Groups::GroupArchivedEvent.new(data: {
          group_id: non_existing_record_id,
          root_namespace_id: non_existing_record_id
        })
      end

      it 'does not raise an error' do
        expect { use_event }.not_to raise_error
      end

      it 'does not delete any pages deployments' do
        expect { use_event }.not_to change { PagesDeployment.count }
      end
    end

    context 'when a project does not have an owner' do
      before do
        allow_next_found_instance_of(Project) do |project|
          allow(project).to receive(:owner).and_return(nil)
        end
      end

      it 'skips that project' do
        expect(Pages::DeleteService).not_to receive(:new)

        use_event
      end
    end

    context 'when group_id is missing from event data' do
      it 'returns early without processing' do
        event = instance_double(Namespaces::Groups::GroupArchivedEvent, data: {})

        expect(Group).not_to receive(:find_by_id)
        expect(Pages::DeleteService).not_to receive(:new)

        described_class.new.handle_event(event)
      end
    end
  end
end
