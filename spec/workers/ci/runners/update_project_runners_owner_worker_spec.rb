# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runners::UpdateProjectRunnersOwnerWorker, '#handle_event', feature_category: :runner do
  let_it_be(:project) { create(:project).tap(&:destroy) }

  let(:project_deleted_event) { Projects::ProjectDeletedEvent.new(data: data) }
  let(:data) do
    { project_id: project.id, namespace_id: project.namespace_id, root_namespace_id: project.root_namespace.id }
  end

  it_behaves_like 'ignores the published event' do
    let(:event) { project_deleted_event }
  end

  it 'does not call Ci::Runners::UpdateProjectRunnersOwnerService' do
    expect(Ci::Runners::UpdateProjectRunnersOwnerService).not_to receive(:new)

    described_class.new.handle_event(project_deleted_event)
  end
end
