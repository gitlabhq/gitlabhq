# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/users/_tabs.html.haml', feature_category: :user_management do
  let_it_be(:admin) { build_stubbed(:admin) }

  before do
    allow(view).to receive(:current_user).and_return(admin)
    allow(view).to receive(:can?).with(admin, :admin_all_resources).and_return(true)
    render
  end

  it 'renders the Cohorts tab' do
    expect(rendered).to have_link(s_('AdminUsers|Cohorts'), href: admin_cohorts_path)
  end
end
