# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runners::UpdateProjectRunnersOwnerWorker, '#handle_event', feature_category: :runner do
  let_it_be(:project) { create(:project).tap(&:destroy) }

  let(:feature_flag_projects) { [project] }
  let(:project_deleted_event) { Projects::ProjectDeletedEvent.new(data: data) }
  let(:data) do
    { project_id: project.id, namespace_id: project.namespace_id, root_namespace_id: project.root_namespace.id }
  end

  before do
    stub_feature_flags(update_project_runners_owner: feature_flag_projects)
  end

  it_behaves_like 'subscribes to event' do
    let(:event) { project_deleted_event }
  end

  it 'calls Ci::Runners::UpdateProjectRunnersOwnerService' do
    expect_next_instance_of(Ci::Runners::UpdateProjectRunnersOwnerService, project.id) do |service|
      expect(service).to receive(:execute)
    end

    described_class.new.handle_event(project_deleted_event)
  end

  context 'with feature flag disabled' do
    let_it_be(:other_project) { create(:project) }

    let(:feature_flag_projects) { [other_project] }

    it 'does not call Ci::Runners::UpdateProjectRunnersOwnerService' do
      allow_next_instance_of(Ci::Runners::UpdateProjectRunnersOwnerService, project.id) do |service|
        expect(service).not_to receive(:execute)
      end

      described_class.new.handle_event(project_deleted_event)
    end
  end
end
