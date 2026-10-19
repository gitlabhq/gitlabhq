# frozen_string_literal: true

RSpec.shared_examples 'packages list' do
  it 'shows a list of packages' do
    wait_for_requests

    packages.each_with_index do |pkg, index|
      package_row = package_table_row(index)

      expect(package_row).to have_content(pkg.name)
      expect(package_row).to have_content(pkg.version)
    end
  end

  def package_table_row(index)
    page.all("#{packages_table_selector} [data-testid=\"package-row\"]")[index].text
  end
end

def packages_table_selector
  '[data-testid="packages-table"]'
end

def click_sort_option(option, ascending)
  wait_for_requests

  # Reset the sort direction
  if page.has_selector?('button[aria-label="Sort direction: Ascending"]', wait: 0) && !ascending
    click_button 'Sort direction'

    wait_for_requests
  end

  find('[data-testid="registry-sort-dropdown"]').click

  page.within('[data-testid="registry-sort-dropdown"] [data-testid="base-dropdown-menu"]') do
    find('.gl-new-dropdown-item', text: option).click
  end

  if ascending
    wait_for_requests

    click_button 'Sort direction'
  end
end
