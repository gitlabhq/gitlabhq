# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runners::UpdateProjectRunnersOwnerWorker, '#handle_event', feature_category: :runner do
  let_it_be(:project) { create(:project).tap(&:destroy) }

  let(:project_deleted_event) { Projects::ProjectDeletedEvent.new(data: data) }
  let(:data) do
    { project_id: project.id, namespace_id: project.namespace_id, root_namespace_id: project.root_namespace.id }
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
end
