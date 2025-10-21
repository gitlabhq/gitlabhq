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

    context 'when fix_graphql_offset_pagination_preloads feature flag is disabled' do
      before do
        stub_feature_flags(fix_graphql_offset_pagination_preloads: false)
      end

      it 'returns the original relation without wrapping' do
        result = offset_paginated_relation.preload(:projects)

        expect(result).not_to be_a(described_class)
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result.preload_values).to include(:projects)
      end
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

    context 'when fix_graphql_offset_pagination_preloads feature flag is disabled' do
      before do
        stub_feature_flags(fix_graphql_offset_pagination_preloads: false)
      end

      it 'returns the original relation without wrapping' do
        result = offset_paginated_relation.includes(:projects)

        expect(result).not_to be_a(described_class)
        expect(result).to be_a(ActiveRecord::Relation)
        expect(result.includes_values).to include(:projects)
      end
    end
  end
end
