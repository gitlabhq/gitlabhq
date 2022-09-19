# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/observability/index' do
  let_it_be(:iframe_url) { "foo.test" }

  before do
    assign(:observability_iframe_src, iframe_url)
  end

  it 'renders as expected' do
    render
    page = Capybara.string(rendered)
    iframe = page.find('iframe#observability-ui-iframe')
    expect(iframe['src']).to eq(iframe_url)
  end
end
