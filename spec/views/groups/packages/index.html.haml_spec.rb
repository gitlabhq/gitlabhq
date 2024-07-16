# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/packages/index.html.haml', feature_category: :package_registry do
  let_it_be(:group) { build(:group) }

  subject { rendered }

  before do
    assign(:group, group)
  end

  it 'renders vue entrypoint' do
    render

    expect(rendered).to have_selector('#js-vue-packages-list')
  end
end
