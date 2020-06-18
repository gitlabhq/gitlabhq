# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::PropagateIntegrationService do
  describe '.propagate' do
    let(:excluded_attributes) { %w[id project_id inherit_from_id instance created_at updated_at title description] }
    let!(:project) { create(:project) }
    let!(:instance_integration) do
      JiraService.create!(
        instance: true,
        active: true,
        push_events: true,
        url: 'http://update-jira.instance.com',
        username: 'user',
        password: 'secret'
      )
    end

    let!(:inherited_integration) do
      JiraService.create!(
        project: create(:project),
        inherit_from_id: instance_integration.id,
        instance: false,
        active: true,
        push_events: false,
        url: 'http://jira.instance.com',
        username: 'user',
        password: 'secret'
      )
    end

    let!(:not_inherited_integration) do
      JiraService.create!(
        project: create(:project),
        inherit_from_id: nil,
        instance: false,
        active: true,
        push_events: false,
        url: 'http://jira.instance.com',
        username: 'user',
        password: 'secret'
      )
    end

    let!(:another_inherited_integration) do
      BambooService.create!(
        project: create(:project),
        inherit_from_id: instance_integration.id,
        instance: false,
        active: true,
        push_events: false,
        bamboo_url: 'http://gitlab.com',
        username: 'mic',
        password: 'password',
        build_key: 'build'
      )
    end

    shared_examples 'inherits settings from integration' do
      it 'updates the inherited integrations' do
        described_class.propagate(integration: instance_integration, overwrite: overwrite)

        expect(integration.reload.inherit_from_id).to eq(instance_integration.id)
        expect(integration.attributes.except(*excluded_attributes))
          .to eq(instance_integration.attributes.except(*excluded_attributes))
      end

      context 'integration with data fields' do
        let(:excluded_attributes) { %w[id service_id created_at updated_at] }

        it 'updates the data fields from inherited integrations' do
          described_class.propagate(integration: instance_integration, overwrite: overwrite)

          expect(integration.reload.data_fields.attributes.except(*excluded_attributes))
            .to eq(instance_integration.data_fields.attributes.except(*excluded_attributes))
        end
      end
    end

    shared_examples 'does not inherit settings from integration' do
      it 'does not update the not inherited integrations' do
        described_class.propagate(integration: instance_integration, overwrite: overwrite)

        expect(integration.reload.attributes.except(*excluded_attributes))
          .not_to eq(instance_integration.attributes.except(*excluded_attributes))
      end
    end

    context 'update only inherited integrations' do
      let(:overwrite) { false }

      it_behaves_like 'inherits settings from integration' do
        let(:integration) { inherited_integration }
      end

      it_behaves_like 'does not inherit settings from integration' do
        let(:integration) { not_inherited_integration }
      end

      it_behaves_like 'does not inherit settings from integration' do
        let(:integration) { another_inherited_integration }
      end

      it_behaves_like 'inherits settings from integration' do
        let(:integration) { project.jira_service }
      end
    end

    context 'update all integrations' do
      let(:overwrite) { true }

      it_behaves_like 'inherits settings from integration' do
        let(:integration) { inherited_integration }
      end

      it_behaves_like 'inherits settings from integration' do
        let(:integration) { not_inherited_integration }
      end

      it_behaves_like 'does not inherit settings from integration' do
        let(:integration) { another_inherited_integration }
      end

      it_behaves_like 'inherits settings from integration' do
        let(:integration) { project.jira_service }
      end
    end

    it 'updates project#has_external_issue_tracker for issue tracker services' do
      described_class.propagate(integration: instance_integration, overwrite: true)

      expect(project.reload.has_external_issue_tracker).to eq(true)
    end

    it 'updates project#has_external_wiki for external wiki services' do
      instance_integration = ExternalWikiService.create!(
        instance: true,
        active: true,
        push_events: false,
        external_wiki_url: 'http://external-wiki-url.com'
      )

      described_class.propagate(integration: instance_integration, overwrite: true)

      expect(project.reload.has_external_wiki).to eq(true)
    end
  end
end
