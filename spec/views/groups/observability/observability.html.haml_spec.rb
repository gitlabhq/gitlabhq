# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/observability/observability.html.haml' do
  let(:iframe_url) { "foo.test" }

  before do
    allow(view).to receive(:observability_iframe_src).and_return(iframe_url)
  end

  it 'renders as expected' do
    render
    page = Capybara.string(rendered)
    div = page.find('#js-observability-app')
    expect(div['data-observability-iframe-src']).to eq(iframe_url)
  end
end
