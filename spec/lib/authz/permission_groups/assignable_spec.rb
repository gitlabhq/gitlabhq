# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::PermissionGroups::Assignable, feature_category: :permissions do
  let(:boundaries) { %w[project] }
  let(:definition) do
    {
      name: 'action_resource',
      description: 'Grants action on resource',
      feature_category: 'feature_category_name',
      # include read_resource twice to ensure uniqueness is handled
      permissions: %w[read_resource write_resource read_resource],
      boundaries: boundaries
    }
  end

  let(:file_path) { 'path/to/resource/action.yml' }
  let(:assignable) { described_class.new(definition, file_path) }

  it_behaves_like 'loadable from yaml' do
    let(:definition_name) { :update_wiki }
  end

  it_behaves_like 'yaml backed permission'

  describe 'class methods' do
    let(:another_assignable) do
      described_class.new({
        name: 'modify_resource',
        description: 'Grants action on other resource',
        permissions: %w[write_resource delete_other_resource write_other_resource]
      }, 'path/to/other_resource/modify.yml')
    end

    before do
      allow(::Authz::PermissionGroups::Assignable).to receive(:all).and_return({
        assignable.name => assignable,
        another_assignable.name => another_assignable
      })
    end

    describe '.all_permissions' do
      it 'returns all unique permissions across all assignables' do
        unique_permissions = %i[read_resource write_resource delete_other_resource write_other_resource]
        expect(described_class.all_permissions).to match_array(unique_permissions)
      end
    end

    describe '.available_definitions' do
      it 'returns all definitions when none are deprecated' do
        expect(described_class.available_definitions).to match_array([assignable, another_assignable])
      end

      context 'when a definition is deprecated' do
        let(:deprecated_assignable) do
          described_class.new({
            name: 'deprecated_resource',
            description: 'A deprecated permission',
            permissions: %w[deprecated_action],
            deprecated: true
          }, 'path/to/deprecated_resource/action.yml')
        end

        before do
          allow(::Authz::PermissionGroups::Assignable).to receive(:all).and_return({
            assignable.name => assignable,
            another_assignable.name => another_assignable,
            deprecated_assignable.name => deprecated_assignable
          })
        end

        it 'excludes deprecated definitions' do
          expect(described_class.available_definitions).to match_array([assignable, another_assignable])
        end

        it 'still includes deprecated definitions in .definitions' do
          expect(described_class.definitions).to include(deprecated_assignable)
        end
      end
    end

    describe '.available_permissions' do
      it 'returns all unique permissions across all assignables' do
        unique_permissions = %i[read_resource write_resource delete_other_resource write_other_resource]
        expect(described_class.available_permissions).to match_array(unique_permissions)
      end

      context 'when a definition is deprecated' do
        let(:deprecated_assignable) do
          described_class.new({
            name: 'deprecated_resource',
            description: 'A deprecated permission',
            permissions: %w[deprecated_action],
            deprecated: true
          }, 'path/to/deprecated_resource/action.yml')
        end

        before do
          allow(::Authz::PermissionGroups::Assignable).to receive(:all).and_return({
            assignable.name => assignable,
            another_assignable.name => another_assignable,
            deprecated_assignable.name => deprecated_assignable
          })
        end

        it 'excludes permissions from deprecated definitions' do
          expect(described_class.available_permissions).not_to include(:deprecated_action)
        end
      end
    end

    describe '.for_permission' do
      it 'returns assignables that include the given permission' do
        expect(described_class.for_permission(:delete_other_resource))
          .to match_array([another_assignable])
      end

      context 'with a string permission name' do
        it 'returns assignables that include the given permission' do
          expect(described_class.for_permission('delete_other_resource'))
            .to match_array([another_assignable])
        end
      end
    end

    describe '.available_for_permission' do
      it 'returns non-deprecated assignables that include the given permission' do
        expect(described_class.available_for_permission(:delete_other_resource))
          .to match_array([another_assignable])
      end

      context 'when the matching assignable is deprecated' do
        let(:deprecated_assignable) do
          described_class.new({
            name: 'deprecated_resource',
            description: 'A deprecated permission',
            permissions: %w[deprecated_action],
            deprecated: true
          }, 'path/to/deprecated_resource/action.yml')
        end

        before do
          allow(::Authz::PermissionGroups::Assignable).to receive(:all).and_return({
            assignable.name => assignable,
            another_assignable.name => another_assignable,
            deprecated_assignable.name => deprecated_assignable
          })
        end

        it 'excludes deprecated assignables' do
          expect(described_class.available_for_permission(:deprecated_action)).to be_empty
        end

        it 'still returns deprecated assignables via .for_permission' do
          expect(described_class.for_permission(:deprecated_action))
            .to match_array([deprecated_assignable])
        end
      end
    end
  end

  describe 'instance methods' do
    describe '#permissions' do
      it 'returns unique permissions as symbols' do
        expect(assignable.permissions).to match_array([:read_resource, :write_resource])
      end

      context 'when permissions key is missing from definition' do
        let(:definition) { { name: 'action_resource' } }

        it 'returns an empty array' do
          expect(assignable.permissions).to eq([])
        end
      end
    end

    describe '#deprecated?' do
      subject(:deprecated) { assignable.deprecated? }

      context 'when deprecated is not set' do
        it { is_expected.to be(false) }
      end

      context 'when deprecated is true' do
        let(:definition) { super().merge(deprecated: true) }

        it { is_expected.to be(true) }
      end

      context 'when deprecated is false' do
        let(:definition) { super().merge(deprecated: false) }

        it { is_expected.to be(false) }
      end
    end

    describe '#available_for' do
      subject { assignable.available_for }

      context 'when available_for is not set' do
        it { is_expected.to eq([]) }
      end

      context 'when available_for is a list of strings' do
        let(:definition) { super().merge(available_for: %w[granular_access_token role]) }

        it { is_expected.to eq([:granular_access_token, :role]) }
      end

      context 'when available_for is a single value' do
        let(:definition) { super().merge(available_for: 'granular_access_token') }

        it { is_expected.to eq([:granular_access_token]) }
      end
    end

    describe '#available_for?' do
      subject { assignable.available_for?(consumer) }

      context 'when available_for is not set' do
        let(:consumer) { :granular_access_token }

        it { is_expected.to be(false) }
      end

      context 'when available_for includes the consumer' do
        let(:definition) { super().merge(available_for: %w[granular_access_token role]) }

        context 'with a symbol' do
          let(:consumer) { :granular_access_token }

          it { is_expected.to be(true) }
        end

        context 'with a string' do
          let(:consumer) { 'granular_access_token' }

          it { is_expected.to be(true) }
        end
      end

      context 'when available_for does not include the consumer' do
        let(:definition) { super().merge(available_for: %w[role]) }
        let(:consumer) { :granular_access_token }

        it { is_expected.to be(false) }
      end
    end

    describe '#boundaries' do
      subject { assignable.boundaries }

      it { is_expected.to eq(boundaries) }

      context 'when boundaries are not defined' do
        let(:boundaries) { nil }

        it { is_expected.to eq([]) }
      end
    end

    describe '#category' do
      subject { assignable.category }

      context 'when not nested under a category directory' do
        let(:file_path) { "#{described_class::BASE_PATH}/resource/action.yml" }

        it { is_expected.to eq('') }
      end

      context 'when nested under a category directory' do
        let(:file_path) { "#{described_class::BASE_PATH}/resource_category/resource/action.yml" }

        it 'returns the name of the category directory' do
          is_expected.to eq('resource_category')
        end
      end
    end

    describe '#category_name' do
      subject { assignable.category_name }

      let(:file_path) { "#{described_class::BASE_PATH}/resource_category/resource/action.yml" }

      before do
        allow(Authz::PermissionGroups::Category).to receive(:get).and_return(nil)
      end

      context 'when category metadata does not exist' do
        it 'returns the category directory name titlecases' do
          is_expected.to eq('Resource Category')
        end
      end

      context 'when category metadata exists without a name' do
        let(:category_definition) do
          Authz::PermissionGroups::Category.new({}, 'source_file')
        end

        before do
          allow(Authz::PermissionGroups::Category).to receive(:get)
            .with('resource_category')
            .and_return(category_definition)
        end

        it 'returns the category directory name titlecased' do
          is_expected.to eq('Resource Category')
        end
      end

      context 'when category metadata exists with a name' do
        let(:category_definition) do
          Authz::PermissionGroups::Category.new({ name: 'Resource Category Display Name' }, 'source_file')
        end

        before do
          allow(Authz::PermissionGroups::Category).to receive(:get)
            .with('resource_category')
            .and_return(category_definition)
        end

        it 'returns the name from category metadata' do
          is_expected.to eq('Resource Category Display Name')
        end
      end
    end

    describe '#resource_name' do
      let(:file_path) { Rails.root.join(described_class::BASE_PATH, 'ci_cd/pipeline/action.yml').to_s }

      context 'when resource has a metadata file with a name' do
        let(:resource_def) do
          Authz::PermissionGroups::Resource.new({ name: 'SSH Key' }, 'path/ssh_key/.metadata.yml')
        end

        before do
          allow(Authz::PermissionGroups::Resource).to receive(:get)
            .with('ci_cd/pipeline')
            .and_return(resource_def)
        end

        it 'returns the name from the metadata' do
          expect(assignable.resource_name).to eq('SSH Key')
        end
      end

      context 'when resource has no metadata file' do
        before do
          allow(Authz::PermissionGroups::Resource).to receive(:get)
            .with('ci_cd/pipeline')
            .and_call_original
        end

        it 'returns the titlecased directory name' do
          expect(assignable.resource_name).to eq('Pipeline')
        end
      end
    end

    describe '#resource_description' do
      let(:file_path) { Rails.root.join(described_class::BASE_PATH, 'ci_cd/pipeline/action.yml').to_s }
      let(:resource_dir) { File.dirname(file_path).sub('action.yml', '') }
      let(:metadata_path) { File.join(File.dirname(file_path), '..', 'pipeline', '.metadata.yml') }

      before do
        allow(Authz::PermissionGroups::Resource).to receive(:get)
          .with('ci_cd/pipeline')
          .and_call_original
      end

      context 'when resource has no metadata file' do
        it 'generates a description from action files' do
          expect(assignable.resource_description).to match(/Grants the ability to .+ pipelines\./)
        end
      end

      context 'when resource has a description with <actions> interpolation' do
        let(:resource_def) do
          Authz::PermissionGroups::Resource.new(
            { description: 'Grants the ability to <actions> CI pipelines.' },
            Rails.root.join(described_class::BASE_PATH, 'ci_cd/pipeline/.metadata.yml').to_s
          )
        end

        before do
          allow(Authz::PermissionGroups::Resource).to receive(:get)
            .with('ci_cd/pipeline')
            .and_return(resource_def)
        end

        it 'interpolates the action list into the description' do
          expect(assignable.resource_description).to match(/Grants the ability to .+ CI pipelines\./)
          expect(assignable.resource_description).not_to include('<actions>')
        end
      end

      context 'when resource has a fully custom description' do
        let(:resource_def) do
          Authz::PermissionGroups::Resource.new(
            { description: 'Grants the ability to delete all artifacts from a project.' },
            Rails.root.join(described_class::BASE_PATH, 'ci_cd/pipeline/.metadata.yml').to_s
          )
        end

        before do
          allow(Authz::PermissionGroups::Resource).to receive(:get)
            .with('ci_cd/pipeline')
            .and_return(resource_def)
        end

        it 'returns the custom description as-is' do
          expect(assignable.resource_description).to eq('Grants the ability to delete all artifacts from a project.')
        end
      end
    end

    describe '#resource_definition' do
      let(:file_path) { Rails.root.join(described_class::BASE_PATH, 'ci_cd/pipeline/action.yml').to_s }
      let(:resource_def) { instance_double(Authz::PermissionGroups::Resource) }

      before do
        allow(Authz::PermissionGroups::Resource).to receive(:get)
          .with('ci_cd/pipeline')
          .and_return(resource_def)
      end

      it 'returns the resource definition for the category and resource' do
        expect(assignable.send(:resource_definition)).to eq(resource_def)
      end

      context 'when not nested under a category directory' do
        let(:file_path) { Rails.root.join(described_class::BASE_PATH, 'pipeline/action.yml').to_s }

        before do
          allow(Authz::PermissionGroups::Resource).to receive(:get)
            .with('/pipeline')
            .and_return(resource_def)
        end

        it 'returns the resource definition with empty category' do
          expect(assignable.send(:resource_definition)).to eq(resource_def)
        end
      end
    end
  end
end
