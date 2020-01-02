# frozen_string_literal: true

shared_examples 'issuable user dropdown behaviors' do
  include FilteredSearchHelpers

  before do
    issuable # ensure we have at least one issuable
    sign_in(user_in_dropdown)
  end

  %w[author assignee].each do |dropdown|
    describe "#{dropdown} dropdown", :js do
      it 'only includes members of the project/group' do
        visit issuables_path

        filtered_search.set("#{dropdown}=")

        expect(find("#js-dropdown-#{dropdown} .filter-dropdown")).to have_content(user_in_dropdown.name)
        expect(find("#js-dropdown-#{dropdown} .filter-dropdown")).not_to have_content(user_not_in_dropdown.name)
      end
    end
  end
end
