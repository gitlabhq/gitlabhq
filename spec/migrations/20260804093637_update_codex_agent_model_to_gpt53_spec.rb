# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateCodexAgentModelToGpt53, migration: :gitlab_main_org, feature_category: :workflow_catalog do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:ai_catalog_items) { table(:ai_catalog_items) }
  let(:ai_catalog_item_versions) { table(:ai_catalog_item_versions) }

  let(:organization) { organizations.create!(name: 'Test Org', path: 'test-org') }

  let(:project) do
    namespace = namespaces.create!(name: 'group', path: 'group', organization_id: organization.id)

    projects.create!(
      name: 'project',
      path: 'project',
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let(:old_model) { 'gpt-5.1-codex' }
  let(:new_model) { 'gpt-5.3-codex' }

  let(:third_party_flow_type) { 3 }
  let(:gitlab_maintained) { 100 }
  let(:unverified) { 0 }

  let!(:codex_version) do
    create_version(create_item(verification_level: gitlab_maintained), definition_for(old_model))
  end

  def yaml_definition_for(model)
    <<~YAML
      image: node:22-slim
      injectGatewayToken: true
      commands:
        - echo "Installing codex"
        - codex exec --config 'model="#{model}"' --config 'model_provider="gitlab"' "task"
      variables:
        - ADDITIONAL_INSTRUCTIONS
    YAML
  end

  def definition_for(model)
    {
      'image' => 'node:22-slim',
      'injectGatewayToken' => true,
      'commands' => [
        'echo "Installing codex"',
        "codex exec --config 'model=\"#{model}\"' --config 'model_provider=\"gitlab\"' \"task\""
      ],
      'variables' => ['ADDITIONAL_INSTRUCTIONS'],
      'yaml_definition' => yaml_definition_for(model)
    }
  end

  def create_item(verification_level:, name: 'Codex Agent by GitLab', project_id: nil)
    ai_catalog_items.create!(
      name: name,
      description: 'Codex Agent',
      public: true,
      organization_id: organization.id,
      project_id: project_id,
      item_type: third_party_flow_type,
      verification_level: verification_level
    )
  end

  def create_version(item, definition)
    ai_catalog_item_versions.create!(
      ai_catalog_item_id: item.id,
      version: '1.0.0',
      organization_id: organization.id,
      schema_version: 1,
      release_date: Time.current,
      definition: definition
    )
  end

  describe '#up' do
    it 'replaces the model everywhere in the definition, leaving the rest intact' do
      migrate!

      definition = ai_catalog_item_versions.find(codex_version.id).definition

      expect(definition).to eq(definition_for(new_model))
      expect(definition.to_json).not_to include(old_model)
    end

    context 'with a project-scoped GitLab-maintained agent, as on GitLab.com' do
      let!(:project_scoped_version) do
        item = create_item(verification_level: gitlab_maintained, project_id: project.id)

        create_version(item, definition_for(old_model))
      end

      it 'replaces the model' do
        migrate!

        expect(ai_catalog_item_versions.find(project_scoped_version.id).definition)
          .to eq(definition_for(new_model))
      end
    end

    context 'with a version already referencing the supported model' do
      let!(:up_to_date_version) do
        create_version(create_item(verification_level: gitlab_maintained), definition_for(new_model))
      end

      it 'leaves it unchanged' do
        migrate!

        expect(ai_catalog_item_versions.find(up_to_date_version.id).definition)
          .to eq(up_to_date_version.definition)
      end
    end

    context 'with a customer-authored agent referencing the same model' do
      let!(:customer_version) do
        item = create_item(
          verification_level: unverified, name: 'My Codex Agent', project_id: project.id
        )

        create_version(item, definition_for(old_model))
      end

      it 'leaves it unchanged' do
        migrate!

        expect(ai_catalog_item_versions.find(customer_version.id).definition)
          .to eq(customer_version.definition)
      end
    end
  end

  describe '#down' do
    it 'does not restore the shut-down model' do
      migrate!
      schema_migrate_down!

      definition = ai_catalog_item_versions.find(codex_version.id).definition

      expect(definition).to eq(definition_for(new_model))
    end
  end
end
