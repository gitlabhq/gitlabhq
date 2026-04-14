# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'explore/groups/index.html.haml', feature_category: :groups_and_projects do
  let_it_be(:user) { build_stubbed(:user) }

  before do
    allow(view).to receive(:explore_groups_app_data).and_return({ test_attr: 'foo' })

    render
  end

  it 'renders the Vue app with data attributes from `explore_groups_app_data`' do
    expect(rendered).to have_selector('#js-explore-groups[data-test-attr="foo"]')
  end
end
