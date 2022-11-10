# frozen_string_literal: true

RSpec.shared_examples 'packages list' do |check_project_name: false|
  it 'shows a list of packages' do
    wait_for_requests

    packages.each_with_index do |pkg, index|
      package_row = package_table_row(index)

      expect(package_row).to have_content(pkg.name)
      expect(package_row).to have_content(pkg.version)
      expect(package_row).to have_content(pkg.project.name) if check_project_name
    end
  end

  def package_table_row(index)
    page.all("#{packages_table_selector} [data-testid=\"package-row\"]")[index].text
  end
end

RSpec.shared_examples 'package details link' do |property|
  it 'navigates to the correct url' do
    page.within(packages_table_selector) do
      click_link package.name
    end

    expect(page).to have_current_path(package_details_path)

    expect(page).to have_css('.packages-app h2[data-testid="title"]', text: package.name)

    expect(page).to have_content('Installation')
    expect(page).to have_content('Registry setup')
  end
end

RSpec.shared_examples 'when there are no packages' do
  it 'displays the empty message' do
    expect(page).to have_content('There are no packages yet')
  end
end

RSpec.shared_examples 'correctly sorted packages list' do |order_by, ascending: false|
  context "ordered by #{order_by} and ascending #{ascending}" do
    before do
      click_sort_option(order_by, ascending)
    end

    it_behaves_like 'packages list'
  end
end

RSpec.shared_examples 'shared package sorting' do
  it_behaves_like 'correctly sorted packages list', 'Type' do
    let(:packages) { [package_two, package_one] }
  end

  it_behaves_like 'correctly sorted packages list', 'Type', ascending: true do
    let(:packages) { [package_one, package_two] }
  end

  it_behaves_like 'correctly sorted packages list', 'Name' do
    let(:packages) { [package_two, package_one] }
  end

  it_behaves_like 'correctly sorted packages list', 'Name', ascending: true do
    let(:packages) { [package_one, package_two] }
  end

  it_behaves_like 'correctly sorted packages list', 'Version' do
    let(:packages) { [package_one, package_two] }
  end

  it_behaves_like 'correctly sorted packages list', 'Version', ascending: true do
    let(:packages) { [package_two, package_one] }
  end

  it_behaves_like 'correctly sorted packages list', 'Published' do
    let(:packages) { [package_two, package_one] }
  end

  it_behaves_like 'correctly sorted packages list', 'Published', ascending: true do
    let(:packages) { [package_one, package_two] }
  end
end

def packages_table_selector
  '[data-testid="packages-table"]'
end

def click_sort_option(option, ascending)
  wait_for_requests

  # Reset the sort direction
  if page.has_selector?('button[aria-label="Sorting Direction: Ascending"]', wait: 0) && !ascending
    click_button 'Sort direction'

    wait_for_requests
  end

  find('[data-testid="registry-sort-dropdown"]').click

  page.within('[data-testid="registry-sort-dropdown"] .dropdown-menu') do
    click_button option
  end

  if ascending
    wait_for_requests

    click_button 'Sort direction'
  end
end
