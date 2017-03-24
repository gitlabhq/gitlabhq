require "spec_helper"

describe TodosHelper do
  describe '#todo_projects_options' do
    let(:projects) { create_list(:empty_project, 3) }
    let(:user)     { create(:user) }

    it 'returns users authorised projects in json format' do
      projects.first.add_developer(user)
      projects.second.add_developer(user)

      allow(helper).to receive(:current_user).and_return(user)

      expected_results = [
        { 'id' => '', 'text' => 'Any Project' },
        { 'id' => projects.second.id, 'text' => projects.second.name_with_namespace },
        { 'id' => projects.first.id, 'text' => projects.first.name_with_namespace }
      ]

      expect(JSON.parse(helper.todo_projects_options)).to match_array(expected_results)
    end
  end
end
