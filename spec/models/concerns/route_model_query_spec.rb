# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Route, 'RouteModelQuery', :aggregate_failures do
  let_it_be(:group1) { create(:group, path: 'Group1') }
  let_it_be(:group2) { create(:group, path: 'Group2') }
  let_it_be(:project1) { create(:project, path: 'Project1', group: group1) }
  let_it_be(:project2) { create(:project, path: 'Project2', group: group2) }

  describe '.find_source_of_path' do
    it 'finds exact match' do
      expect(described_class.find_source_of_path('Group1')).to eq(group1)
      expect(described_class.find_source_of_path('Group2/Project2')).to eq(project2)

      expect(described_class.find_source_of_path('GROUP1')).to be_nil
      expect(described_class.find_source_of_path('GROUP2/PROJECT2')).to be_nil
    end

    it 'finds case insensitive match' do
      expect(described_class.find_source_of_path('Group1', case_sensitive: false)).to eq(group1)
      expect(described_class.find_source_of_path('Group2/Project2', case_sensitive: false)).to eq(project2)

      expect(described_class.find_source_of_path('GROUP1', case_sensitive: false)).to eq(group1)
      expect(described_class.find_source_of_path('GROUP2/PROJECT2', case_sensitive: false)).to eq(project2)
    end
  end
end
