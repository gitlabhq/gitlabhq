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

RSpec.shared_examples 'pipelines on packages list' do
  let_it_be(:pipelines) do
    %w[c83d6e391c22777fca1ed3012fce84f633d7fed0
      d83d6e391c22777fca1ed3012fce84f633d7fed0].map do |sha|
      create(:ci_pipeline, project: project, sha: sha)
    end
  end

  before do
    pipelines.each do |pipeline|
      create(:package_build_info, package: package, pipeline: pipeline)
    end
  end

  it 'shows the latest pipeline' do
    # Test after reload
    page.evaluate_script 'window.location.reload()'

    wait_for_requests

    expect(page).to have_content('d83d6e39')
  end
end

RSpec.shared_examples 'package details link' do |property|
  before do
    stub_application_setting(npm_package_requests_forwarding: false)
  end

  it 'navigates to the correct url' do
    page.within(packages_table_selector) do
      click_link package.name
    end

    expect(page).to have_current_path(package_details_path)

    expect(page).to have_css('.packages-app h1[data-testid="page-heading"]', text: package.name)

    expect(page).to have_content('Installation')
    expect(page).to have_content('Registry setup')
    expect(page).to have_content('Other versions 0')
  end

  context 'with other versions' do
    let_it_be(:npm_package1) { create(:npm_package, project: project, name: 'zzz', version: '1.1.0') }
    let_it_be(:npm_package2) { create(:npm_package, project: project, name: 'zzz', version: '1.2.0') }

    before do
      page.within(packages_table_selector) do
        first(:link, package.name).click
      end
    end

    it 'shows tab with count' do
      expect(page).to have_content('Other versions 2')
    end

    it 'visiting tab shows total on page' do
      click_link 'Other versions'

      expect(page).to have_content('2 versions')
    end

    it 'deleting version updates count' do
      click_link 'Other versions'

      find('[data-testid="delete-dropdown"]', match: :first).click
      find('[data-testid="action-delete"]', match: :first).click
      click_button('Permanently delete')

      expect(page).to have_content 'Package deleted successfully'

      expect(page).to have_content('Other versions 1')
      expect(page).to have_content('1 version')

      expect(page).not_to have_content('1.0.0')
      expect(page).to have_content('1.1.0')
      expect(page).to have_content('1.2.0')
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

  context 'when sorted by name ascending' do
    before do
      click_sort_option('Name', true)
    end

    it 'updates query params to contain orderBy:name and sort:asc' do
      queryparams = Rack::Utils.parse_query(URI.parse(current_url).query)
      expect(queryparams).to include(
        'orderBy' => 'name',
        'sort' => 'asc'
      )
    end
  end
end

RSpec.shared_examples 'shared package filtering' do
  include FilteredSearchHelpers

  context 'filters by Type' do
    let(:packages) { [npm_package] }

    before do
      select_tokens('Type', 'npm', submit: true, input_text: 'Filter results')
    end

    it_behaves_like 'packages list'

    it 'updates query params' do
      queryparams = Rack::Utils.parse_query(URI.parse(current_url).query)
      expect(queryparams).to eq(
        'type' => 'npm',
        'orderBy' => 'created_at',
        'sort' => 'desc'
      )
    end

    context 'when cleared' do
      before do
        wait_for_requests
        click_button 'Clear'
      end

      it 'resets query params' do
        queryparams = Rack::Utils.parse_query(URI.parse(current_url).query)
        expect(queryparams).to eq(
          'orderBy' => 'created_at',
          'sort' => 'desc'
        )
      end
    end
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
