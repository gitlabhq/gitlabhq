# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddIncidentSettingsToAllExistingProjects, :migration do
  let(:project_incident_management_settings) { table(:project_incident_management_settings) }
  let(:labels) { table(:labels) }
  let(:label_links) { table(:label_links) }
  let(:issues) { table(:issues) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }

  RSpec.shared_examples 'setting not added' do
    it 'does not add settings' do
      migrate!

      expect { migrate! }.not_to change { IncidentManagement::ProjectIncidentManagementSetting.count }
    end
  end

  RSpec.shared_examples 'project has no incident settings' do
    it 'has no settings' do
      migrate!

      expect(settings).to eq(nil)
    end
  end

  RSpec.shared_examples 'no change to incident settings' do
    it 'does not change existing settings' do
      migrate!

      expect(settings.create_issue).to eq(existing_create_issue)
    end
  end

  RSpec.shared_context 'with incident settings' do
    let(:existing_create_issue) { false }
    before do
      project_incident_management_settings.create!(
        project_id: project.id,
        create_issue: existing_create_issue
      )
    end
  end

  describe 'migrate!' do
    let(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }
    let!(:project) { projects.create!(namespace_id: namespace.id) }
    let(:settings) { project_incident_management_settings.find_by(project_id: project.id) }

    context 'when project does not have incident label' do
      context 'does not have incident settings' do
        include_examples 'setting not added'
        include_examples 'project has no incident settings'
      end

      context 'and has incident settings' do
        include_context 'with incident settings'

        include_examples 'setting not added'
        include_examples 'no change to incident settings'
      end
    end

    context 'when project has incident labels' do
      before do
        issue = issues.create!(project_id: project.id)
        incident_label_attrs = IncidentManagement::CreateIncidentLabelService::LABEL_PROPERTIES
        incident_label = labels.create!(project_id: project.id, **incident_label_attrs)
        label_links.create!(target_id: issue.id, label_id: incident_label.id, target_type: 'Issue')
      end

      context 'when project has incident settings' do
        include_context 'with incident settings'

        include_examples 'setting not added'
        include_examples 'no change to incident settings'
      end

      context 'does not have incident settings' do
        it 'adds incident settings with old defaults' do
          migrate!

          expect(settings.create_issue).to eq(true)
          expect(settings.send_email).to eq(false)
          expect(settings.issue_template_key).to eq(nil)
        end
      end
    end
  end
end
