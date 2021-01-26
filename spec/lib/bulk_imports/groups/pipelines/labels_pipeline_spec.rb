# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Pipelines::LabelsPipeline do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:entity) do
    create(
      :bulk_import_entity,
      source_full_path: 'source/full/path',
      destination_name: 'My Destination Group',
      destination_namespace: group.full_path,
      group: group
    )
  end

  let(:context) do
    BulkImports::Pipeline::Context.new(
      current_user: user,
      entity: entity
    )
  end

  def extractor_data(title:, has_next_page:, cursor: "")
    {
      "data" => {
        "group" => {
          "labels" => {
            "page_info" => {
              "end_cursor" => cursor,
              "has_next_page" => has_next_page
            },
            "nodes" => [
              {
                "title" => title,
                "description" => "desc",
                "color" => "#428BCA"
              }
            ]
          }
        }
      }
    }
  end

  describe '#run' do
    it 'imports a group labels' do
      first_page = extractor_data(title: 'label1', has_next_page: true, cursor: 'nextPageCursor')
      last_page = extractor_data(title: 'label2', has_next_page: false)

      allow_next_instance_of(BulkImports::Common::Extractors::GraphqlExtractor) do |extractor|
        allow(extractor)
          .to receive(:extract)
          .and_return(first_page, last_page)
      end

      expect { subject.run(context) }.to change(Label, :count).by(2)

      label = group.labels.order(:created_at).last

      expect(label.title).to eq('label2')
      expect(label.description).to eq('desc')
      expect(label.color).to eq('#428BCA')
    end
  end

  describe 'pipeline parts' do
    it { expect(described_class).to include_module(BulkImports::Pipeline) }
    it { expect(described_class).to include_module(BulkImports::Pipeline::Runner) }

    it 'has extractors' do
      expect(described_class.get_extractor)
        .to eq(
          klass: BulkImports::Common::Extractors::GraphqlExtractor,
          options: {
            query: BulkImports::Groups::Graphql::GetLabelsQuery
          }
        )
    end

    it 'has transformers' do
      expect(described_class.transformers)
        .to contain_exactly(
          { klass: BulkImports::Common::Transformers::HashKeyDigger, options: { key_path: %w[data group labels] } },
          { klass: BulkImports::Common::Transformers::ProhibitedAttributesTransformer, options: nil }
        )
    end

    it 'has loaders' do
      expect(described_class.get_loader).to eq(klass: BulkImports::Groups::Loaders::LabelsLoader, options: nil)
    end
  end
end
