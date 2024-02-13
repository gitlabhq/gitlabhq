# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Pipelines::BadgesPipeline, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project) }

  let(:entity) { create(:bulk_import_entity, group: group) }
  let(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let(:context) { BulkImports::Pipeline::Context.new(tracker) }

  subject(:pipeline) { described_class.new(context) }

  describe '#run' do
    let(:first_page) { extracted_data(has_next_page: true) }
    let(:last_page) { extracted_data(name: 'badge2') }

    before do
      allow_next_instance_of(BulkImports::Common::Extractors::RestExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(first_page, last_page)
      end

      allow(subject).to receive(:set_source_objects_counter)
    end

    it 'imports a group badge' do
      expect { pipeline.run }.to change(Badge, :count).by(2)

      badge = group.badges.last

      expect(badge.name).to eq('badge2')
      expect(badge.link_url).to eq(badge_data['link_url'])
      expect(badge.image_url).to eq(badge_data['image_url'])
    end

    it 'skips already imported records' do
      expect { pipeline.run }.to change(Badge, :count).by(2)

      expect { pipeline.run }.to not_change(Badge, :count)
    end

    context 'when project entity' do
      let(:first_page) { extracted_data(has_next_page: true) }
      let(:last_page) { extracted_data(name: 'badge2', kind: 'project') }
      let(:entity) { create(:bulk_import_entity, :project_entity, project: project) }

      it 'imports a project badge & skips group badge' do
        expect { pipeline.run }.to change(Badge, :count).by(1)

        badge = project.badges.last

        expect(badge.name).to eq('badge2')
        expect(badge.link_url).to eq(badge_data['link_url'])
        expect(badge.image_url).to eq(badge_data['image_url'])
        expect(badge.type).to eq('ProjectBadge')
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

      context 'when project entity & group badge' do
        let(:entity) { create(:bulk_import_entity, :project_entity, project: project) }

        it 'returns' do
          expect(subject.transform(context, { 'name' => 'test', 'kind' => 'group' })).to be_nil
        end
      end
    end

    def badge_data(name = 'badge', kind = 'group')
      {
        'name' => name,
        'link_url' => 'https://gitlab.example.com',
        'image_url' => 'https://gitlab.example.com/image.png',
        'kind' => kind
      }
    end

    def extracted_data(name: 'badge', kind: 'group', has_next_page: false)
      page_info = {
        'has_next_page' => has_next_page,
        'next_page' => has_next_page ? '2' : nil
      }

      BulkImports::Pipeline::ExtractedData.new(data: [badge_data(name, kind)], page_info: page_info)
    end
  end
end
