require 'spec_helper'

describe 'dashboard/projects/_nav.html.haml' do
  it 'highlights All tab by default' do
    render

    expect(rendered).to have_css('a.active', text: 'All')
  end

  it 'highlights Personal tab personal param is present' do
    controller.params[:personal] = true

    render

    expect(rendered).to have_css('a.active', text: 'Personal')
  end
end
