# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integration do
  let_it_be(:project_1) { create(:project) }
  let_it_be(:project_2) { create(:project) }
  let_it_be(:project_3) { create(:project) }
  let_it_be(:instance_integration) { create(:jira_service, :instance) }

  before do
    create(:jira_service, project: project_1, inherit_from_id: instance_integration.id)
    create(:jira_service, project: project_2, inherit_from_id: nil)
    create(:slack_service, project: project_3, inherit_from_id: nil)
  end

  describe '.with_custom_integration_for' do
    it 'returns projects with custom integrations' do
      expect(Project.with_custom_integration_for(instance_integration)).to contain_exactly(project_2)
    end
  end

  describe '.without_integration' do
    it 'returns projects without integration' do
      expect(Project.without_integration(instance_integration)).to contain_exactly(project_3)
    end
  end
end
