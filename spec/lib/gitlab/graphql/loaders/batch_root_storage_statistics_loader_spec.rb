# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Loaders::BatchRootStorageStatisticsLoader do
  describe '#find' do
    it 'only queries once for project statistics' do
      stats = create_list(:namespace_root_storage_statistics, 2)
      namespace1 = stats.first.namespace
      namespace2 = stats.last.namespace

      expect do
        described_class.new(namespace1.id).find
        described_class.new(namespace2.id).find
      end.not_to exceed_query_limit(1)
    end
  end
end
