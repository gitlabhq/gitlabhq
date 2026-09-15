# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/organizations/users/_form.html.haml', :with_current_organization, feature_category: :organization do
  let_it_be(:user) { build_stubbed(:user) }

  before do
    assign(:user, user)
    view.content_for(:organization_section) do
      view.content_tag(:div, nil, data: { testid: 'organization-section' })
    end
  end

  it_behaves_like 'admin user form with only the organization section'
end
