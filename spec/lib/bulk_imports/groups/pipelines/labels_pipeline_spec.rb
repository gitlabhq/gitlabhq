# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Pipelines::LabelsPipeline do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:timestamp) { Time.new(2020, 01, 01).utc }

  let_it_be(:entity) do
    create(
      :bulk_import_entity,
      source_full_path: 'source/full/path',
      destination_name: 'My Destination Group',
      destination_namespace: group.full_path,
      group: group
    )
  end

  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  subject { described_class.new(context) }

  describe '#run' do
    it 'imports a group labels' do
      first_page = extracted_data(title: 'label1', has_next_page: true)
      last_page = extracted_data(title: 'label2')

      allow_next_instance_of(BulkImports::Common::Extractors::GraphqlExtractor) do |extractor|
        allow(extractor)
          .to receive(:extract)
          .and_return(first_page, last_page)
      end

      expect { subject.run }.to change(Label, :count).by(2)

      label = group.labels.order(:created_at).last

      expect(label.title).to eq('label2')
      expect(label.description).to eq('desc')
      expect(label.color).to eq('#428BCA')
      expect(label.created_at).to eq(timestamp)
      expect(label.updated_at).to eq(timestamp)
    end
  end

  describe '#load' do
    it 'creates the label' do
      data = label_data('label')

      expect { subject.load(context, data) }.to change(Label, :count).by(1)

      label = group.labels.first

      data.each do |key, value|
        expect(label[key]).to eq(value)
      end
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
          { klass: BulkImports::Common::Transformers::ProhibitedAttributesTransformer, options: nil }
        )
    end
  end

  def label_data(title)
    {
      'title' => title,
      'description' => 'desc',
      'color' => '#428BCA',
      'created_at' => timestamp.to_s,
      'updated_at' => timestamp.to_s
    }
  end

  def extracted_data(title:, has_next_page: false)
    page_info = {
      'has_next_page' => has_next_page,
      'next_page' => has_next_page ? 'cursor' : nil
    }

    BulkImports::Pipeline::ExtractedData.new(data: [label_data(title)], page_info: page_info)
  end
end
