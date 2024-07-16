# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/packages/packages/index.html.haml', feature_category: :package_registry do
  let_it_be(:project) { build(:project) }

  subject { rendered }

  before do
    assign(:project, project)
  end

  it 'renders vue entrypoint' do
    render

    expect(rendered).to have_selector('#js-vue-packages-list')
  end
end
