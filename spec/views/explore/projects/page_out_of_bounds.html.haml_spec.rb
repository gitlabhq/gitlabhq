# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'explore/projects/page_out_of_bounds.html.haml', feature_category: :groups_and_projects do
  let(:page_limit) { 10 }
  let(:unsafe_param) { 'hacked_using_unsafe_param!' }

  before do
    assign(:max_page_number, page_limit)

    controller.params[:action] = 'index'
    controller.params[:host] = unsafe_param
    controller.params[:protocol] = unsafe_param
    controller.params[:sort] = 'name_asc'
  end

  it 'removes unsafe params from the link' do
    render

    href = "/explore/projects?page=#{page_limit}&sort=name_asc"
    button_text = format(_("Back to page %{number}"), number: page_limit)
    expect(rendered).to have_link(button_text, href: href)
    expect(rendered).not_to include(unsafe_param)
  end
end
