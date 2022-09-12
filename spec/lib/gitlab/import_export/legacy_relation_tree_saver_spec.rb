# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::LegacyRelationTreeSaver do
  let(:exportable) { create(:group) }
  let(:relation_tree_saver) { described_class.new }
  let(:tree) { {} }

  describe '#serialize' do
    let(:serializer) { instance_double(Gitlab::ImportExport::FastHashSerializer) }

    it 'uses FastHashSerializer' do
      expect(Gitlab::ImportExport::FastHashSerializer)
        .to receive(:new)
        .with(exportable, tree)
        .and_return(serializer)

      expect(serializer).to receive(:execute)

      relation_tree_saver.serialize(exportable, tree)
    end
  end
end
