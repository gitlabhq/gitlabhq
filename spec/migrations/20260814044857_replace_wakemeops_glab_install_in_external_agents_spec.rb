# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ReplaceWakemeopsGlabInstallInExternalAgents,
  migration: :gitlab_main_org,
  feature_category: :workflow_catalog do
  let(:organizations) { table(:organizations) }
  let!(:claude_version) { create_seeded_agent(name: 'Claude Agent by GitLab', definition: claude_definition) }
  let!(:codex_version) { create_seeded_agent(name: 'Codex Agent by GitLab', definition: codex_definition) }
  let(:ai_catalog_items) { table(:ai_catalog_items) }
  let(:ai_catalog_item_versions) { table(:ai_catalog_item_versions) }

  let(:organization) { organizations.create!(name: 'Test Org', path: 'test-org') }

  let(:third_party_flow_type) { 3 }
  let(:gitlab_maintained) { 100 }
  let(:unverified) { 0 }

  let(:install_command) { described_class::INSTALL_COMMAND }
  let(:path_command) { described_class::PATH_COMMAND }

  def claude_definition
    yaml = <<~YAML
      injectGatewayToken: true
      image: node:22-slim
      commands:
        - echo "Installing claude"
        - echo "Installing glab"
        - apt-get update -q && apt-get install -y curl wget gpg git && rm -rf /var/lib/apt/lists/*
        - curl -sSL https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository | bash
        - apt-get install -y glab
        - mkdir -p ~/.config/glab-cli
        - export ANTHROPIC_AUTH_TOKEN=$AI_FLOW_AI_GATEWAY_TOKEN
      variables:
        - ADDITIONAL_INSTRUCTIONS
    YAML

    YAML.safe_load(yaml, permitted_classes: [], aliases: false).merge('yaml_definition' => yaml)
  end

  def codex_definition
    yaml = <<~YAML
      image: node:22-slim
      injectGatewayToken: true
      commands:
        - echo "Installing codex"
        - npm install --global @openai/codex
        - echo "Installing glab"
        - export OPENAI_API_KEY=$AI_FLOW_AI_GATEWAY_TOKEN
        - apt-get update --quiet && apt-get install --yes curl wget gpg git && rm --recursive --force /var/lib/apt/lists/*
        - curl --silent --show-error --location "https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository" | bash
        - apt-get install --yes glab
        - mkdir -p ~/.config/glab-cli
        - echo "Running Codex"
      variables:
        - ADDITIONAL_INSTRUCTIONS
    YAML

    YAML.safe_load(yaml, permitted_classes: [], aliases: false).merge('yaml_definition' => yaml)
  end

  def fixed_claude_definition
    yaml = <<~YAML
      injectGatewayToken: true
      image: node:22-slim
      commands:
        - echo "Installing claude"
        - echo "Installing glab"
        - apt-get update -q && apt-get install -y curl wget gpg git && rm -rf /var/lib/apt/lists/*
        - |
          #{install_command}
        - #{path_command}
        - mkdir -p ~/.config/glab-cli
        - export ANTHROPIC_AUTH_TOKEN=$AI_FLOW_AI_GATEWAY_TOKEN
      variables:
        - ADDITIONAL_INSTRUCTIONS
    YAML

    YAML.safe_load(yaml, permitted_classes: [], aliases: false).merge('yaml_definition' => yaml)
  end

  def fixed_codex_definition
    yaml = <<~YAML
      image: node:22-slim
      injectGatewayToken: true
      commands:
        - echo "Installing codex"
        - npm install --global @openai/codex
        - echo "Installing glab"
        - export OPENAI_API_KEY=$AI_FLOW_AI_GATEWAY_TOKEN
        - apt-get update --quiet && apt-get install --yes curl wget gpg git && rm --recursive --force /var/lib/apt/lists/*
        - |
          #{install_command}
        - #{path_command}
        - mkdir -p ~/.config/glab-cli
        - echo "Running Codex"
      variables:
        - ADDITIONAL_INSTRUCTIONS
    YAML

    YAML.safe_load(yaml, permitted_classes: [], aliases: false).merge('yaml_definition' => yaml)
  end

  def create_seeded_agent(
    name:, definition:, item_type: third_party_flow_type,
    verification_level: gitlab_maintained)
    item = ai_catalog_items.create!(
      name: name,
      description: 'An external agent',
      public: true,
      organization_id: organization.id,
      item_type: item_type,
      verification_level: verification_level
    )

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
    it 'migrates the Claude agent definition to the fixed install' do
      migrate!

      expect(ai_catalog_item_versions.find(claude_version.id).definition).to eq(fixed_claude_definition)
    end

    it 'migrates the Codex agent definition to the fixed install' do
      migrate!

      expect(ai_catalog_item_versions.find(codex_version.id).definition).to eq(fixed_codex_definition)
    end

    context 'with a non-latest version that still references wakemeops' do
      let!(:older_version) do
        item = ai_catalog_items.create!(
          name: 'Claude Agent by GitLab',
          description: 'An external agent',
          public: true,
          organization_id: organization.id,
          item_type: third_party_flow_type,
          verification_level: gitlab_maintained
        )

        older = ai_catalog_item_versions.create!(
          ai_catalog_item_id: item.id,
          version: '1.0.0',
          organization_id: organization.id,
          schema_version: 1,
          release_date: Time.current,
          definition: claude_definition
        )

        ai_catalog_item_versions.create!(
          ai_catalog_item_id: item.id,
          version: '1.1.0',
          organization_id: organization.id,
          schema_version: 1,
          release_date: Time.current,
          definition: claude_definition
        )

        older
      end

      it 'updates the non-latest version too' do
        migrate!

        expect(ai_catalog_item_versions.find(older_version.id).definition).to eq(fixed_claude_definition)
      end
    end

    context 'with a customer-authored agent with the same name but unverified' do
      let!(:customer_version) do
        create_seeded_agent(
          name: 'Claude Agent by GitLab',
          definition: claude_definition,
          verification_level: unverified
        )
      end

      it 'does not update the customer-authored version' do
        migrate!

        expect(ai_catalog_item_versions.find(customer_version.id).definition)
          .to eq(customer_version.definition)
      end
    end

    context 'with a version that already has the fixed install command' do
      let!(:fixed_version) do
        create_seeded_agent(name: 'Claude Agent by GitLab', definition: fixed_claude_definition)
      end

      it 'leaves the already-fixed version unchanged' do
        migrate!

        expect(ai_catalog_item_versions.find(fixed_version.id).definition)
          .to eq(fixed_version.definition)
      end
    end
  end

  describe '#down' do
    it 'does not restore the wakemeops install' do
      migrate!
      schema_migrate_down!

      definition = ai_catalog_item_versions.find(claude_version.id).definition

      expect(definition.to_json).not_to include('wakemeops')
    end
  end
end
