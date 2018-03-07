require 'spec_helper'

describe Gitlab::MultiCollectionPaginator do
  subject(:paginator) { described_class.new(Project.all.order(:id), Group.all.order(:id), per_page: 3) }

  it 'combines both collections' do
    project = create(:project)
    group = create(:group)

    expect(paginator.paginate(1)).to eq([project, group])
  end

  it 'includes elements second collection if first collection is empty' do
    group = create(:group)

    expect(paginator.paginate(1)).to eq([group])
  end

  context 'with a full first page' do
    let!(:all_groups) { create_list(:group, 4) }
    let!(:all_projects) { create_list(:project, 4) }

    it 'knows the total count of the collection' do
      expect(paginator.total_count).to eq(8)
    end

    it 'fills the first page with elements of the first collection' do
      expect(paginator.paginate(1)).to eq(all_projects.take(3))
    end

    it 'fils the second page with a mixture of of the first & second collection' do
      first_collection_element = all_projects.last
      second_collection_elements = all_groups.take(2)

      expected_collection = [first_collection_element] + second_collection_elements

      expect(paginator.paginate(2)).to eq(expected_collection)
    end

    it 'fils the last page with elements from the second collection' do
      expected_collection = all_groups[-2..-1]

      expect(paginator.paginate(3)).to eq(expected_collection)
    end
  end
end
