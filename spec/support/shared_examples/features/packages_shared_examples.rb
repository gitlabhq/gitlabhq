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
    page.all("#{packages_table_selector} > [data-qa-selector=\"package_row\"]")[index].text
  end
end

RSpec.shared_examples 'package details link' do |property|
  let(:package) { packages.first }

  before do
    stub_feature_flags(packages_details_one_column: false)
  end

  it 'navigates to the correct url' do
    page.within(packages_table_selector) do
      click_link package.name
    end

    expect(page).to have_current_path(project_package_path(package.project, package))

    expect(page).to have_css('.packages-app h1[data-testid="title"]', text: package.name)

    page.within(%Q([name="#{package.name}"])) do
      expect(page).to have_content('Installation')
      expect(page).to have_content('Registry setup')
    end
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
  '[data-qa-selector="packages-table"]'
end

def click_sort_option(option, ascending)
  page.within('.gl-sorting') do
    # Reset the sort direction
    click_button 'Sort direction' if page.has_selector?('svg[aria-label="Sorting Direction: Ascending"]', wait: 0)

    find('button.dropdown-menu-toggle').click

    page.within('.dropdown-menu') do
      click_button option
    end

    click_button 'Sort direction' if ascending
  end
end
