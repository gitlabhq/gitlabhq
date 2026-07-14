# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Projects::Transformers::ProjectAttributesTransformer, feature_category: :importers do
  describe '#transform' do
    let_it_be_with_reload(:bulk_import) { create(:bulk_import) }

    let(:destination_group) { create(:group) }
    let(:destination_namespace) { destination_group&.full_path }

    let(:entity) do
      create(
        :bulk_import_entity,
        source_type: :project_entity,
        bulk_import: bulk_import,
        source_full_path: 'source/full/path',
        destination_slug: 'Destination-Project-Name',
        destination_namespace: destination_namespace
      )
    end

    let(:tracker) { create(:bulk_import_tracker, entity: entity) }
    let(:context) { BulkImports::Pipeline::Context.new(tracker) }

    let(:data) do
      {
        'name' => 'Gitlab Test',
        'description' => 'Source description',
        'visibility_level' => 10,
        'created_at' => '2016-11-18T09:29:42.634Z',
        'shared_runners_enabled' => true,
        'build_timeout' => 3600
      }
    end

    subject(:transformed_data) { described_class.new.transform(context, data) }

    it 'includes the cleaned source attributes', :aggregate_failures do
      expect(transformed_data).to include('description' => 'Source description', 'build_timeout' => 3600)
    end

    it 'uniquifies project name' do
      create(:project, group: destination_group, name: 'Gitlab Test')

      expect(transformed_data[:name]).to eq('Gitlab Test_1')
    end

    it 'adds path as normalized destination slug' do
      expect(transformed_data[:path]).to eq(entity.destination_slug.downcase)
    end

    it 'adds created_at from the source data' do
      expect(transformed_data[:created_at]).to eq(data['created_at'])
    end

    it 'adds import type' do
      expect(transformed_data[:import_type]).to eq(Import::SOURCE_OFFLINE_TRANSFER.to_s)
    end

    it 'adds namespace_id' do
      expect(transformed_data[:namespace_id]).to eq(destination_group.id)
    end

    it 'sets visibility_level from the integer source attribute' do
      expect(transformed_data[:visibility_level]).to eq(Gitlab::VisibilityLevel::INTERNAL)
    end

    context 'when data is nil' do
      let(:data) { nil }

      it { is_expected.to be_nil }
    end

    context 'when destination namespace already has a project with the same name' do
      before do
        create(:project, group: destination_group, name: 'Gitlab Test', path: 'project')
        create(:project, group: destination_group, name: 'Gitlab Test_1', path: 'project_1')
      end

      it 'makes the name unique by appending a counter' do
        expect(transformed_data['name']).to eq('Gitlab Test_2')
      end
    end

    context 'when destination namespace already has a project with the same path' do
      before do
        create(:project, group: destination_group, name: 'Other Project', path: 'destination-project-name')
      end

      it 'makes the path unique by appending a counter' do
        expect(transformed_data['path']).to eq('destination-project-name_1')
      end
    end

    context 'when destination_namespace cannot be resolved in the import organization' do
      let(:destination_group) { nil }
      let(:destination_namespace) { 'namespace-in-another-org' }

      before do
        create(:group, organization: create(:organization), path: 'namespace-in-another-org')
      end

      it 'raises a NamespaceNotFoundError' do
        expect { transformed_data }.to raise_error(
          described_class::NamespaceNotFoundError,
          /not found in the import organization/
        )
      end
    end

    describe 'visibility level' do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:public_group) { create(:group, :public) }
      let_it_be(:internal_group) { create(:group, :internal) }
      let_it_be(:private_group) { create(:group, :private) }

      let(:private) { Gitlab::VisibilityLevel::PRIVATE }
      let(:internal) { Gitlab::VisibilityLevel::INTERNAL }
      let(:public) { Gitlab::VisibilityLevel::PUBLIC }

      where(:source_level, :destination_group, :restricted_level, :expected) do
        ref(:public)   | ref(:public_group)   | nil            | ref(:public)
        ref(:public)   | ref(:public_group)   | ref(:public)   | ref(:internal)
        ref(:public)   | ref(:internal_group) | nil            | ref(:internal)
        ref(:public)   | ref(:private_group)  | nil            | ref(:private)
        ref(:internal) | ref(:public_group)   | nil            | ref(:internal)
        ref(:internal) | ref(:public_group)   | ref(:internal) | ref(:private)
        ref(:internal) | ref(:internal_group) | nil            | ref(:internal)
        ref(:internal) | ref(:private_group)  | nil            | ref(:private)
        ref(:private)  | ref(:public_group)   | nil            | ref(:private)
        ref(:private)  | ref(:private_group)  | nil            | ref(:private)
      end

      with_them do
        let(:data) { { 'name' => 'Test', 'visibility_level' => source_level } }

        before do
          stub_application_setting(restricted_visibility_levels: [restricted_level])
        end

        it 'clamps visibility to the allowed level' do
          expect(transformed_data[:visibility_level]).to eq(expected)
        end
      end
    end
  end
end
