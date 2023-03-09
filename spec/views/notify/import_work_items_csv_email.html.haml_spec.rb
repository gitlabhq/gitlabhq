# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'notify/import_work_items_csv_email.html.haml', feature_category: :team_planning do
  let_it_be(:user) { create(:user) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
  let_it_be(:project) { create(:project) } # rubocop:disable RSpec/FactoryBot/AvoidCreate

  let(:parse_error) { "Error parsing CSV file. Please make sure it has the correct format" }

  before do
    assign(:user, user)
    assign(:project, project)
    assign(:results, results)

    render
  end

  shared_examples_for 'no records created' do
    specify do
      expect(rendered).to have_content("No work items have been imported.")
      expect(rendered).not_to have_content("work items successfully imported.")
    end
  end

  shared_examples_for 'work item records created' do
    specify do
      expect(rendered).not_to have_content("No work items have been imported.")
      expect(rendered).to have_content("work items successfully imported.")
    end
  end

  shared_examples_for 'contains project link' do
    specify do
      expect(rendered).to have_link(project.full_name, href: project_url(project))
    end
  end

  shared_examples_for 'contains parse error' do
    specify do
      expect(rendered).to have_content(parse_error)
    end
  end

  shared_examples_for 'does not contain parse error' do
    specify do
      expect(rendered).not_to have_content(parse_error)
    end
  end

  context 'when no errors found while importing' do
    let(:results) { { success: 3, parse_error: false } }

    it 'renders correctly' do
      expect(rendered).not_to have_content("Errors found on line")
    end

    it_behaves_like 'contains project link'
    it_behaves_like 'work item records created'
    it_behaves_like 'does not contain parse error'
  end

  context 'when import errors reported' do
    let(:results) { { success: 3, error_lines: [5, 6, 7], parse_error: false } }

    it 'renders correctly' do
      expect(rendered).to have_content("Errors found on lines: #{results[:error_lines].join(', ')}. \
Please check that these lines have the following fields: title, type")
    end

    it_behaves_like 'contains project link'
    it_behaves_like 'work item records created'
    it_behaves_like 'does not contain parse error'
  end

  context 'when parse error reported while importing' do
    let(:results) { { success: 0, parse_error: true } }

    it_behaves_like 'contains project link'
    it_behaves_like 'no records created'
    it_behaves_like 'contains parse error'
  end

  context 'when work item type column contains blank entries' do
    let(:results) { { success: 0, parse_error: false, type_errors: { blank: [4] } } }

    it 'renders with missing work item message' do
      expect(rendered).to have_content("Work item type is empty")
    end

    it_behaves_like 'contains project link'
    it_behaves_like 'no records created'
    it_behaves_like 'does not contain parse error'
  end

  context 'when work item type column contains missing entries' do
    let(:results) { { success: 0, parse_error: false, type_errors: { missing: [5] } } }

    it 'renders with missing work item message' do
      expect(rendered).to have_content("Work item type cannot be found or is not supported.")
    end

    it_behaves_like 'contains project link'
    it_behaves_like 'no records created'
    it_behaves_like 'does not contain parse error'
  end

  context 'when work item type column contains disallowed entries' do
    let(:results) { { success: 0, parse_error: false, type_errors: { disallowed: [6] } } }

    it 'renders with missing work item message' do
      expect(rendered).to have_content("Work item type is not available.")
    end

    it_behaves_like 'contains project link'
    it_behaves_like 'no records created'
    it_behaves_like 'does not contain parse error'
  end

  context 'when CSV contains multiple kinds of work item type errors' do
    let(:results) { { success: 0, parse_error: false, type_errors: { blank: [4], missing: [5], disallowed: [6] } } }

    it 'renders with missing work item message' do
      expect(rendered).to have_content("Work item type is empty")
      expect(rendered).to have_content("Work item type cannot be found or is not supported.")
      expect(rendered).to have_content("Work item type is not available. Please check your license and permissions.")
    end

    it_behaves_like 'contains project link'
    it_behaves_like 'no records created'
    it_behaves_like 'does not contain parse error'
  end
end
