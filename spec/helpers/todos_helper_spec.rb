require "spec_helper"

describe TodosHelper do
  describe '#todos_count_format' do
    it 'shows fuzzy count for 100 or more items' do
      expect(helper.todos_count_format(100)).to eq '99+'
      expect(helper.todos_count_format(1000)).to eq '99+'
    end

    it 'shows exact count for 99 or fewer items' do
      expect(helper.todos_count_format(99)).to eq '99'
      expect(helper.todos_count_format(50)).to eq '50'
      expect(helper.todos_count_format(1)).to eq '1'
    end
  end

  describe '#todo_projects_options' do
    let(:projects) { create_list(:project, 3) }
    let(:user)     { create(:user) }

    it 'returns users authorised projects in json format' do
      projects.first.add_developer(user)
      projects.second.add_developer(user)

      allow(helper).to receive(:current_user).and_return(user)

      expected_results = [
        { 'id' => '', 'text' => 'Any Project' },
        { 'id' => projects.second.id, 'text' => projects.second.full_name },
        { 'id' => projects.first.id, 'text' => projects.first.full_name }
      ]

      expect(JSON.parse(helper.todo_projects_options)).to match_array(expected_results)
    end
  end
end
