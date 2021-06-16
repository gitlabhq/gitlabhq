# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::LegacyRelationTreeSaver do
  let(:exportable) { create(:group) }
  let(:relation_tree_saver) { described_class.new }
  let(:tree) { {} }

  describe '#serialize' do
    shared_examples 'FastHashSerializer with batch size' do |batch_size|
      let(:serializer) { instance_double(Gitlab::ImportExport::FastHashSerializer) }

      it 'uses FastHashSerializer' do
        expect(Gitlab::ImportExport::FastHashSerializer)
          .to receive(:new)
          .with(exportable, tree, batch_size: batch_size)
          .and_return(serializer)

        expect(serializer).to receive(:execute)

        relation_tree_saver.serialize(exportable, tree)
      end
    end

    context 'when export_reduce_relation_batch_size feature flag is enabled' do
      before do
        stub_feature_flags(export_reduce_relation_batch_size: true)
      end

      include_examples 'FastHashSerializer with batch size', Gitlab::ImportExport::Json::StreamingSerializer::SMALLER_BATCH_SIZE
    end

    context 'when export_reduce_relation_batch_size feature flag is disabled' do
      before do
        stub_feature_flags(export_reduce_relation_batch_size: false)
      end

      include_examples 'FastHashSerializer with batch size', Gitlab::ImportExport::Json::StreamingSerializer::BATCH_SIZE
    end
  end
end
