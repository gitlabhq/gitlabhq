# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'dashboard/projects/_blank_state_welcome.html.haml' do
  let_it_be(:user) { create(:user) }

  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  it 'has a doc_url' do
    render

    expect(rendered).to have_link(href: Gitlab::Saas.doc_url)
  end
end
