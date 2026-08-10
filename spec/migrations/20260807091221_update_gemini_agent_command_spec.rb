# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateGeminiAgentCommand, migration: :gitlab_main_org, feature_category: :workflow_catalog do
  let(:organizations) { table(:organizations) }
  let(:ai_catalog_items) { table(:ai_catalog_items) }
  let(:ai_catalog_item_versions) { table(:ai_catalog_item_versions) }

  let(:organization) { organizations.create!(name: 'Organization', path: 'organization') }

  let(:old_command) { 'gemini --yolo --debug --prompt' }
  let(:new_command) { 'gemini --yolo --debug --skip-trust --model gemini-2.5-pro --prompt' }

  let(:gemini_item) { create_item(name: 'Develop with Gemini Agent') }
  let(:other_item) { create_item(name: 'Other Agent') }

  let!(:gemini_version) { create_version(gemini_item, definition_for(old_command)) }
  let!(:other_version) { create_version(other_item, definition_for(old_command)) }

  before do
    stub_const("#{described_class}::ITEM_ID", gemini_item.id)
  end

  def yaml_definition_for(command)
    <<~YAML
      image: node:22-slim
      commands:
        - npm install --global @google/gemini-cli
        - #{command} "$AI_FLOW_INPUT"
      variables:
        - GOOGLE_CREDENTIALS
    YAML
  end

  def definition_for(command)
    {
      'image' => 'node:22-slim',
      'commands' => [
        'npm install --global @google/gemini-cli',
        %(#{command} "$AI_FLOW_INPUT")
      ],
      'variables' => ['GOOGLE_CREDENTIALS'],
      'yaml_definition' => yaml_definition_for(command)
    }
  end

  def create_item(name:)
    ai_catalog_items.create!(
      name: name,
      description: 'An external agent',
      public: true,
      organization_id: organization.id,
      item_type: 3,
      verification_level: 100
    )
  end

  def create_version(item, definition, version: '1.0.0')
    ai_catalog_item_versions.create!(
      ai_catalog_item_id: item.id,
      version: version,
      organization_id: organization.id,
      schema_version: 1,
      release_date: Time.current,
      definition: definition
    )
  end

  context 'on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

    describe '#up' do
      it 'updates the command everywhere in the definition, leaving the rest intact' do
        migrate!

        definition = ai_catalog_item_versions.find(gemini_version.id).definition

        expect(definition).to eq(definition_for(new_command))
      end

      it 'does not update versions of other items' do
        migrate!

        expect(ai_catalog_item_versions.find(other_version.id).definition).to eq(other_version.definition)
      end

      context 'with another version of the same item' do
        let!(:earlier_version) do
          create_version(gemini_item, definition_for(old_command), version: '0.9.0')
        end

        it 'updates every version of the item' do
          migrate!

          expect(ai_catalog_item_versions.find(earlier_version.id).definition)
            .to eq(definition_for(new_command))
        end
      end

      context 'with a version already using the updated command' do
        let!(:up_to_date_version) do
          create_version(gemini_item, definition_for(new_command), version: '1.1.0')
        end

        it 'leaves it unchanged' do
          migrate!

          expect(ai_catalog_item_versions.find(up_to_date_version.id).definition)
            .to eq(up_to_date_version.definition)
        end
      end
    end

    describe '#down' do
      it 'restores the original command' do
        migrate!
        schema_migrate_down!

        expect(ai_catalog_item_versions.find(gemini_version.id).definition)
          .to eq(definition_for(old_command))
      end
    end
  end

  context 'on self-managed' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(false)
    end

    describe '#up' do
      it 'does not update any versions' do
        migrate!

        expect(ai_catalog_item_versions.find(gemini_version.id).definition).to eq(gemini_version.definition)
      end
    end
  end
end
