# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Loaders::BatchProjectStatisticsLoader do
  describe '#find' do
    it 'only queries once for project statistics' do
      stats = create_list(:project_statistics, 2)
      project1 = stats.first.project
      project2 = stats.last.project

      expect do
        described_class.new(project1.id).find
        described_class.new(project2.id).find
      end.not_to exceed_query_limit(1)
    end
  end
end
