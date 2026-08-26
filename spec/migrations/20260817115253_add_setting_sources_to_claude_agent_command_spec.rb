# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddSettingSourcesToClaudeAgentCommand, migration: :gitlab_main_org,
  feature_category: :workflow_catalog do
  let(:organizations) { table(:organizations) }
  let(:ai_catalog_items) { table(:ai_catalog_items) }
  let(:ai_catalog_item_versions) { table(:ai_catalog_item_versions) }

  let(:organization) { organizations.create!(name: 'Test Org', path: 'test-org') }

  let(:old_flags) { '--permission-mode acceptEdits --verbose' }
  let(:new_flags) { "--permission-mode acceptEdits --setting-sources '' --verbose" }

  let(:third_party_flow_type) { 3 }
  let(:flow_type) { 2 }
  let(:gitlab_maintained) { 100 }
  let(:unverified) { 0 }

  let(:claude_item) { create_item(verification_level: gitlab_maintained) }

  let!(:claude_version) { create_version(claude_item, definition_for(old_flags)) }
  let!(:earlier_claude_version) { create_version(claude_item, definition_for(old_flags), version: '0.9.0') }

  def yaml_definition_for(flags)
    <<~YAML
      injectGatewayToken: true
      image: node:22-slim
      commands:
        - echo "Running claude"
        - claude --allowedTools="Bash(glab:*)" #{flags} --output-format stream-json -p "task"
      variables:
        - ADDITIONAL_INSTRUCTIONS
    YAML
  end

  def definition_for(flags)
    {
      'injectGatewayToken' => true,
      'image' => 'node:22-slim',
      'commands' => [
        'echo "Running claude"',
        %(claude --allowedTools="Bash(glab:*)" #{flags} --output-format stream-json -p "task")
      ],
      'variables' => ['ADDITIONAL_INSTRUCTIONS'],
      'yaml_definition' => yaml_definition_for(flags)
    }
  end

  def create_item(verification_level:, name: 'Claude Agent by GitLab', item_type: third_party_flow_type)
    ai_catalog_items.create!(
      name: name,
      description: 'Claude Agent',
      organization_id: organization.id,
      item_type: item_type,
      verification_level: verification_level
    )
  end

  def create_version(item, definition, version: '1.0.0')
    ai_catalog_item_versions.create!(
      ai_catalog_item_id: item.id,
      version: version,
      organization_id: organization.id,
      schema_version: 1,
      definition: definition
    )
  end

  describe '#up' do
    it 'adds the flag to every version, leaving the rest of the definition intact' do
      migrate!

      expect(ai_catalog_item_versions.find(claude_version.id).definition).to eq(definition_for(new_flags))
      expect(ai_catalog_item_versions.find(earlier_claude_version.id).definition).to eq(definition_for(new_flags))
    end

    context 'with a version already using the flag' do
      let!(:up_to_date_version) do
        create_version(create_item(verification_level: gitlab_maintained), definition_for(new_flags))
      end

      it 'leaves it unchanged' do
        migrate!

        expect(ai_catalog_item_versions.find(up_to_date_version.id).definition).to eq(up_to_date_version.definition)
      end
    end

    context 'with a customer-authored agent using the same flags' do
      let!(:customer_version) do
        item = create_item(verification_level: unverified, name: 'My Claude Agent')

        create_version(item, definition_for(old_flags))
      end

      it 'leaves it unchanged' do
        migrate!

        expect(ai_catalog_item_versions.find(customer_version.id).definition).to eq(customer_version.definition)
      end
    end

    context 'with an item that is not a third-party flow' do
      let!(:flow_version) do
        item = create_item(verification_level: gitlab_maintained, item_type: flow_type)

        create_version(item, definition_for(old_flags))
      end

      it 'leaves it unchanged' do
        migrate!

        expect(ai_catalog_item_versions.find(flow_version.id).definition).to eq(flow_version.definition)
      end
    end
  end
end
