# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Pipelines::NamespaceSettingsPipeline, feature_category: :importers do
  subject(:pipeline) { described_class.new(context) }

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, namespace_settings: create(:namespace_settings)) }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }
  let_it_be(:entity) { create(:bulk_import_entity, :group_entity, group: group, bulk_import: bulk_import) }
  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  before do
    group.add_owner(user)

    allow(pipeline).to receive(:set_source_objects_counter)
  end

  describe '#run' do
    before do
      allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
        namespace_settings_attributes = {
          'namespace_id' => 22,
          'prevent_forking_outside_group' => true,
          'prevent_sharing_groups_outside_hierarchy' => true
        }
        allow(extractor).to receive(:extract).and_return(
          BulkImports::Pipeline::ExtractedData.new(data: [[namespace_settings_attributes, 0]])
        )
      end
    end

    it 'imports allowed namespace settings attributes' do
      expect(Groups::UpdateService).to receive(:new).with(
        group, user, { prevent_sharing_groups_outside_hierarchy: true }
      ).and_call_original

      pipeline.run

      expect(group.namespace_settings).to have_attributes(prevent_sharing_groups_outside_hierarchy: true)
    end
  end

  describe '#transform' do
    it 'fetches only allowed attributes and symbolize keys' do
      all_model_attributes = NamespaceSetting.new.attributes

      transformed_data = pipeline.transform(context, [all_model_attributes, 0])

      expect(transformed_data.keys).to match_array([:prevent_sharing_groups_outside_hierarchy])
    end

    context 'when there is no data to transform' do
      it do
        namespace_settings_attributes = nil

        transformed_data = pipeline.transform(context, namespace_settings_attributes)

        expect(transformed_data).to eq(nil)
      end
    end
  end

  describe '#after_run' do
    it 'calls extractor#remove_tmpdir' do
      expect_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
        expect(extractor).to receive(:remove_tmpdir)
      end

      context = instance_double(BulkImports::Pipeline::Context)

      pipeline.after_run(context)
    end
  end
end
