# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Pipelines::LabelsPipeline do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:cursor) { 'cursor' }
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

  def extractor_data(title:, has_next_page:, cursor: nil)
    data = [
      {
        'title' => title,
        'description' => 'desc',
        'color' => '#428BCA'
      }
    ]

    page_info = {
      'end_cursor' => cursor,
      'has_next_page' => has_next_page
    }

    BulkImports::Pipeline::ExtractedData.new(data: data, page_info: page_info)
  end

  describe '#run' do
    it 'imports a group labels' do
      first_page = extractor_data(title: 'label1', has_next_page: true, cursor: cursor)
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

  describe '#after_run' do
    context 'when extracted data has next page' do
      it 'updates tracker information and runs pipeline again' do
        data = extractor_data(title: 'label', has_next_page: true, cursor: cursor)

        expect(subject).to receive(:run).with(context)

        subject.after_run(context, data)

        tracker = entity.trackers.find_by(relation: :labels)

        expect(tracker.has_next_page).to eq(true)
        expect(tracker.next_page).to eq(cursor)
      end
    end

    context 'when extracted data has no next page' do
      it 'updates tracker information and does not run pipeline' do
        data = extractor_data(title: 'label', has_next_page: false)

        expect(subject).not_to receive(:run).with(context)

        subject.after_run(context, data)

        tracker = entity.trackers.find_by(relation: :labels)

        expect(tracker.has_next_page).to eq(false)
        expect(tracker.next_page).to be_nil
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

    it 'has loaders' do
      expect(described_class.get_loader).to eq(klass: BulkImports::Groups::Loaders::LabelsLoader, options: nil)
    end
  end
end
