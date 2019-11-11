# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::RelationTreeSaver do
  let(:exportable) { create(:group) }
  let(:relation_tree_saver) { described_class.new }
  let(:tree) { {} }

  describe '#serialize' do
    context 'when :export_fast_serialize feature is enabled' do
      let(:serializer) { instance_double(Gitlab::ImportExport::FastHashSerializer) }

      before do
        stub_feature_flags(export_fast_serialize: true)
      end

      it 'uses FastHashSerializer' do
        expect(Gitlab::ImportExport::FastHashSerializer)
          .to receive(:new)
          .with(exportable, tree)
          .and_return(serializer)

        expect(serializer).to receive(:execute)

        relation_tree_saver.serialize(exportable, tree)
      end
    end

    context 'when :export_fast_serialize feature is disabled' do
      before do
        stub_feature_flags(export_fast_serialize: false)
      end

      it 'is serialized via built-in `as_json`' do
        expect(exportable).to receive(:as_json).with(tree)

        relation_tree_saver.serialize(exportable, tree)
      end
    end
  end
end
