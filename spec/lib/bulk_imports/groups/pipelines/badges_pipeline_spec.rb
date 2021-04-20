# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Pipelines::BadgesPipeline do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

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
    it 'imports a group badge' do
      first_page = extracted_data(has_next_page: true)
      last_page  = extracted_data(name: 'badge2')

      allow_next_instance_of(BulkImports::Common::Extractors::RestExtractor) do |extractor|
        allow(extractor)
          .to receive(:extract)
          .and_return(first_page, last_page)
      end

      expect { subject.run }.to change(Badge, :count).by(2)

      badge = group.badges.last

      expect(badge.name).to eq('badge2')
      expect(badge.link_url).to eq(badge_data['link_url'])
      expect(badge.image_url).to eq(badge_data['image_url'])
    end

    describe '#load' do
      it 'creates a badge' do
        expect { subject.load(context, badge_data) }.to change(Badge, :count).by(1)

        badge = group.badges.first

        badge_data.each do |key, value|
          expect(badge[key]).to eq(value)
        end
      end

      it 'does nothing when the data is blank' do
        expect { subject.load(context, nil) }.not_to change(Badge, :count)
      end
    end

    describe '#transform' do
      it 'return transformed badge hash' do
        badge = subject.transform(context, badge_data)

        expect(badge[:name]).to eq('badge')
        expect(badge[:link_url]).to eq(badge_data['link_url'])
        expect(badge[:image_url]).to eq(badge_data['image_url'])
        expect(badge.keys).to contain_exactly(:name, :link_url, :image_url)
      end

      context 'when data is blank' do
        it 'does nothing when the data is blank' do
          expect(subject.transform(context, nil)).to be_nil
        end
      end
    end

    describe 'pipeline parts' do
      it { expect(described_class).to include_module(BulkImports::Pipeline) }
      it { expect(described_class).to include_module(BulkImports::Pipeline::Runner) }

      it 'has extractors' do
        expect(described_class.get_extractor)
          .to eq(
            klass: BulkImports::Common::Extractors::RestExtractor,
            options: {
              query: BulkImports::Groups::Rest::GetBadgesQuery
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

    def badge_data(name = 'badge')
      {
        'name' => name,
        'link_url' => 'https://gitlab.example.com',
        'image_url' => 'https://gitlab.example.com/image.png'
      }
    end

    def extracted_data(name: 'badge', has_next_page: false)
      page_info = {
        'has_next_page' => has_next_page,
        'next_page' => has_next_page ? '2' : nil
      }

      BulkImports::Pipeline::ExtractedData.new(data: [badge_data(name)], page_info: page_info)
    end
  end
end
