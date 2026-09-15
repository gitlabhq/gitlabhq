# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Pagination::OffsetPaginatedRelation, feature_category: :api do
  let(:relation) { User.all }
  let(:offset_paginated_relation) { described_class.new(relation) }

  describe '#preload' do
    it 'returns a new OffsetPaginatedRelation instance, preserving #preload behaviour' do
      result = offset_paginated_relation.preload(:projects)

      expect(result).to be_a(described_class)
      expect(result).not_to eq(offset_paginated_relation)
      expect(result.__getobj__.preload_values).to include(:projects)
      expect(result.__getobj__).to be_a(ActiveRecord::Relation)
    end
  end

  describe '#includes' do
    it 'returns a new OffsetPaginatedRelation instance preserving the #includes behaviour' do
      result = offset_paginated_relation.includes(:projects)

      expect(result).to be_a(described_class)
      expect(result).not_to eq(offset_paginated_relation)
      expect(result.__getobj__.includes_values).to include(:projects)
      expect(result.__getobj__).to be_a(ActiveRecord::Relation)
    end
  end

  describe '#merge' do
    it 'returns a new OffsetPaginatedRelation instance, preserving #merge behaviour' do
      result = offset_paginated_relation.merge(User.where(id: 1))

      expect(result).to be_a(described_class)
      expect(result).not_to eq(offset_paginated_relation)
      expect(result.__getobj__.where_values_hash).to include('id' => 1)
      expect(result.__getobj__).to be_a(ActiveRecord::Relation)
    end

    it 'still selects the offset connection' do
      result = offset_paginated_relation.merge(User.where(id: 1))

      expect(GitlabSchema.connections.wrapper_for(result))
        .to eq(Gitlab::Graphql::Pagination::OffsetActiveRecordRelationConnection)
    end
  end

  describe '#unscope' do
    it 'returns a new OffsetPaginatedRelation instance, preserving #unscope behaviour' do
      result = described_class.new(User.where(id: 1)).unscope(where: :id)

      expect(result).to be_a(described_class)
      expect(result.__getobj__.where_values_hash).to be_empty
      expect(result.__getobj__).to be_a(ActiveRecord::Relation)
    end

    it 'still selects the offset connection' do
      result = described_class.new(User.where(id: 1)).unscope(where: :id)

      expect(GitlabSchema.connections.wrapper_for(result))
        .to eq(Gitlab::Graphql::Pagination::OffsetActiveRecordRelationConnection)
    end
  end
end
