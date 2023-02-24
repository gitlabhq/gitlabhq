# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'notify/import_work_items_csv_email.html.haml', feature_category: :team_planning do
  let_it_be(:user) { create(:user) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
  let_it_be(:project) { create(:project) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
  let_it_be(:correct_results) { { success: 3, parse_error: false } }
  let_it_be(:errored_results) { { success: 3, error_lines: [5, 6, 7], parse_error: false } }
  let_it_be(:parse_error_results) { { success: 0, parse_error: true } }

  before do
    assign(:user, user)
    assign(:project, project)
  end

  context 'when no errors found while importing' do
    before do
      assign(:results, correct_results)
    end

    it 'renders correctly' do
      render

      expect(rendered).to have_link(project.full_name, href: project_url(project))
      expect(rendered).to have_content("3 work items imported")
      expect(rendered).not_to have_content("Errors found on line")
      expect(rendered).not_to have_content(
        "Error parsing CSV file. Please make sure it has the correct format: \
a delimited text file that uses a comma to separate values.")
    end
  end

  context 'when import errors reported' do
    before do
      assign(:results, errored_results)
    end

    it 'renders correctly' do
      render

      expect(rendered).to have_content("Errors found on lines: #{errored_results[:error_lines].join(', ')}. \
Please check that these lines have the following fields: title")
      expect(rendered).not_to have_content("Error parsing CSV file. Please make sure it has the correct format: \
a delimited text file that uses a comma to separate values.")
    end
  end

  context 'when parse error reported while importing' do
    before do
      assign(:results, parse_error_results)
    end

    it 'renders with parse error' do
      render

      expect(rendered).to have_content("Error parsing CSV file. \
Please make sure it has the correct format: a delimited text file that uses a comma to separate values.")
    end
  end
end
