# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Members::GroupLinksCollection, feature_category: :groups_and_projects do
  let_it_be(:group_link) { create(:group_group_link) }
  let_it_be(:project_link) { create(:project_group_link) }

  subject(:collection) { described_class.new([group_link, project_link], page: 2, total_count: 4, per_page: 2) }

  describe '#project_links' do
    it 'returns project links' do
      expect(collection.project_links).to contain_exactly(project_link)
    end
  end

  describe '#group_links' do
    it 'returns group links' do
      expect(collection.group_links).to contain_exactly(group_link)
    end
  end

  describe '#total_count' do
    specify { expect(collection.total_count).to be(4) }
  end

  describe '#current_page' do
    specify { expect(collection.current_page).to be(2) }
  end

  describe '#limit_value' do
    specify { expect(collection.limit_value).to be(2) }
  end
end
