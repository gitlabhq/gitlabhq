# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Authz::PermissionGroups::Resource, feature_category: :permissions do
  describe '.config_path' do
    it 'returns the glob pattern for metadata files' do
      expect(described_class.config_path).to include('**/.metadata.yml')
    end
  end

  describe '.all' do
    it 'loads all resources with hierarchical identifiers' do
      resources = described_class.all
      first_key = resources.each_key.first

      expect(resources).not_to be_empty
      expect(first_key).to be_a(Symbol)
      expect(first_key.to_s).to include('/')
    end
  end

  describe '.get' do
    context 'when the resource has a metadata file' do
      it 'retrieves the resource' do
        resource = described_class.get(:"ci_cd/ci_config")

        expect(resource).to be_present
        expect(resource.resource_name).to eq('CI Config')
      end
    end

    context 'when the resource does not have a metadata file' do
      it 'returns a default resource with an empty definition' do
        resource = described_class.get(:"ci_cd/pipeline")

        expect(resource).to be_present
        expect(resource.definition).to eq({})
        expect(resource.resource_name).to eq('Pipeline')
      end
    end
  end

  describe 'instance methods' do
    let(:definition) { {} }
    let(:file_path) { "config/authz/permission_groups/assignable_permissions/ci_cd/pipeline/.metadata.yml" }

    subject(:resource) { described_class.new(definition, file_path) }

    describe '#description' do
      context 'with an explicit description using <actions> interpolation' do
        let(:definition) { { description: 'Grants the ability to <actions> CI pipelines.' } }

        it 'interpolates the action list' do
          allow(Dir).to receive(:glob).and_return(
            %w[/path/create.yml /path/delete.yml /path/read.yml]
          )

          expect(resource.description).to eq('Grants the ability to create, delete, and read CI pipelines.')
        end
      end

      context 'with an explicit description without interpolation' do
        let(:definition) { { description: 'Grants the ability to delete all artifacts from a project.' } }

        it 'returns the description as-is' do
          expect(resource.description).to eq('Grants the ability to delete all artifacts from a project.')
        end
      end

      context 'with actions that contain underscores' do
        let(:definition) { { description: 'Grants the ability to <actions> CI pipelines.' } }

        it 'replaces underscores with spaces in action names' do
          allow(Dir).to receive(:glob).and_return(
            %w[/path/admin_read.yml /path/create.yml]
          )

          expect(resource.description).to eq('Grants the ability to admin read and create CI pipelines.')
        end
      end

      context 'without an explicit description' do
        let(:definition) { {} }

        it 'generates a default description from actions' do
          allow(Dir).to receive(:glob).and_return(
            %w[/path/create.yml /path/read.yml]
          )

          expect(resource.description).to eq('Grants the ability to create and read pipelines.')
        end
      end

      context 'without an explicit description but with a name' do
        let(:definition) { { name: 'SSH Key' } }
        let(:file_path) { "config/authz/permission_groups/assignable_permissions/system_access/ssh_key/.metadata.yml" }

        it 'preserves casing from the name field' do
          allow(Dir).to receive(:glob).and_return(%w[/path/read.yml])

          expect(resource.description).to eq('Grants the ability to read SSH Keys.')
        end
      end
    end

    describe '#resource_name' do
      context 'when definition includes a name' do
        let(:definition) { { name: 'Custom Name' } }

        it 'returns the name from the definition' do
          expect(resource.resource_name).to eq('Custom Name')
        end
      end

      context 'when definition does not include a name' do
        it 'returns the titlecased directory name' do
          expect(resource.resource_name).to eq('Pipeline')
        end
      end

      context 'with multi-word directory name' do
        let(:file_path) { "config/authz/permission_groups/assignable_permissions/ci_cd/merge_request/.metadata.yml" }

        it 'returns the titlecased directory name' do
          expect(resource.resource_name).to eq('Merge Request')
        end
      end
    end
  end
end
