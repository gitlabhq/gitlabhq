# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/mirrors/_mirror_repos_list', feature_category: :source_code_management do
  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- rendering the partial requires persisted records and pagination
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  before do
    assign(:project, project)
    assign(:remote_mirrors, project.remote_mirrors.page(1))
    allow(view).to receive_messages(current_user: user, params: { page: '1' })
  end

  it 'renders the Vue mirror table root with populated data attributes without raising', :aggregate_failures do
    expect { render }.not_to raise_error

    element = Capybara.string(rendered).find('#js-mirror-table')

    expect(element['data-mirrors']).to be_present
    expect(element['data-project-id']).to eq(project.id.to_s)
    expect(element['data-settings-enabled']).to be_present
    expect(element['data-repository-mirrors-available']).to be_present
  end

  it 'does not render the legacy HAML table when the feature flag is enabled', :aggregate_failures do
    render

    expect(rendered).to have_css('#js-mirror-table')
    expect(rendered).not_to have_css('.table-responsive')
  end

  it 'renders the legacy HAML table when the feature flag is disabled' do
    stub_feature_flags(vue_mirror_table: false)

    render

    expect(rendered).to have_css('.table-responsive')
  end
end
