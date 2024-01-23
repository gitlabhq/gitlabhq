# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Pipelines::GroupAttributesPipeline, feature_category: :importers do
  subject(:pipeline) { described_class.new(context) }

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }
  let_it_be(:entity) { create(:bulk_import_entity, :group_entity, group: group, bulk_import: bulk_import) }
  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  let(:group_attributes) do
    {
      'id' => 1,
      'name' => 'Group name',
      'path' => 'group-path',
      'description' => 'description',
      'avatar' => {
        'url' => nil
      },
      'membership_lock' => true,
      'traversal_ids' => [
        2
      ]
    }
  end

  describe '#run' do
    before do
      allow_next_instance_of(BulkImports::Common::Extractors::JsonExtractor) do |extractor|
        allow(extractor).to receive(:extract).and_return(
          BulkImports::Pipeline::ExtractedData.new(data: group_attributes)
        )
      end

      allow(pipeline).to receive(:set_source_objects_counter)
    end

    it 'imports allowed group attributes' do
      expect(Groups::UpdateService).to receive(:new).with(group, user, { membership_lock: true }).and_call_original

      pipeline.run

      expect(group).to have_attributes(membership_lock: true)
    end
  end

  describe '#transform' do
    it 'fetches only allowed attributes and symbolize keys' do
      transformed_data = pipeline.transform(context, group_attributes)

      expect(transformed_data).to eq({ membership_lock: true })
    end

    context 'when there is no data to transform' do
      let(:group_attributes) { nil }

      it do
        transformed_data = pipeline.transform(context, group_attributes)

        expect(transformed_data).to eq(nil)
      end
    end
  end

  describe '#after_run' do
    it 'calls extractor#remove_tmpdir' do
      expect_next_instance_of(BulkImports::Common::Extractors::JsonExtractor) do |extractor|
        expect(extractor).to receive(:remove_tmpdir)
      end

      pipeline.after_run(nil)
    end
  end

  describe '.relation' do
    it { expect(described_class.relation).to eq('self') }
  end
end
