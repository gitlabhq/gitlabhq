# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Common::Pipelines::BadgesPipeline, feature_category: :importers do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, owners: current_user) }
  let_it_be_with_reload(:bulk_import) do
    create(:bulk_import, :with_offline_configuration, user: current_user)
  end

  let(:entity) do
    create(
      :bulk_import_entity,
      bulk_import: bulk_import,
      source_full_path: 'source/full/path',
      destination_namespace: group.full_path,
      group: group
    )
  end

  let(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let(:context) { BulkImports::Pipeline::Context.new(tracker) }
  let(:badge_data) do
    {
      'name' => 'Group badge',
      'link_url' => 'https://gitlab.example.com',
      'image_url' => 'https://gitlab.example.com/image.png',
      'type' => 'GroupBadge'
    }
  end

  let(:extracted_data) { BulkImports::Pipeline::ExtractedData.new(data: [[badge_data, 0]]) }

  subject(:pipeline) { described_class.new(context) }

  before do
    allow(pipeline).to receive(:set_source_objects_counter)
    allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
      allow(extractor).to receive(:extract).and_return(extracted_data)
      allow(extractor).to receive(:remove_tmpdir)
    end
  end

  it 'uses the badges NDJSON file' do
    expect(described_class.get_extractor).to eq(
      klass: BulkImports::Common::Extractors::NdjsonExtractor,
      options: { relation: 'badges' }
    )
  end

  it 'is a file extraction pipeline' do
    expect(described_class.file_extraction_pipeline?).to be(true)
  end

  it 'uses the base pipeline transformers' do
    expect(described_class.transformers).to eq(described_class.superclass.transformers)
  end

  it 'unwraps an NDJSON badge record before transforming it' do
    expect(pipeline.transform(context, [badge_data, 0])).to eq(
      name: 'Group badge',
      link_url: badge_data['link_url'],
      image_url: badge_data['image_url']
    )
  end

  it 'skips a missing badge' do
    expect(pipeline.transform(context, [nil, 0])).to be_nil
  end

  it 'imports a group badge', :aggregate_failures do
    expect { pipeline.run }.to change { group.badges.count }.by(1)

    expect(group.badges.last).to have_attributes(
      name: 'Group badge',
      link_url: badge_data['link_url'],
      image_url: badge_data['image_url']
    )
  end

  it 'removes the temporary extraction directory after import' do
    extractor = pipeline.send(:file_extractor)
    expect(extractor).to receive(:remove_tmpdir)

    pipeline.after_run(nil)
  end
end
