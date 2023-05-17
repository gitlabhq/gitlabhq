# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/milestones/_issuables.html.haml' do
  let(:issuables_size) { 100 }

  before do
    allow(view).to receive_messages(
      title: nil,
      id: nil,
      show_project_name: nil,
      dom_class: '',
      issuables: double(length: issuables_size).as_null_object
    )

    stub_template 'shared/milestones/_issuable.html.haml' => ''
  end

  it 'shows the issuables count if show_counter is true' do
    render 'shared/milestones/issuables', show_counter: true
    expect(rendered).to have_content('100')
  end

  it 'does not show the issuables count if show_counter is false' do
    render 'shared/milestones/issuables', show_counter: false
    expect(rendered).not_to have_content('100')
  end

  describe 'a high issuables count' do
    let(:issuables_size) { 1000 }

    it 'shows a delimited number if show_counter is true' do
      render 'shared/milestones/issuables', show_counter: true
      expect(rendered).to have_content('1,000')
    end
  end
end
