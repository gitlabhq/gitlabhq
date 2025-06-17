# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/users/_user_type.html.haml', feature_category: :user_management do
  let_it_be(:user) { build(:user) }
  let_it_be(:is_current_user) { false }

  before do
    assign(:user, user)
    render
  end

  def render
    super(partial: 'admin/users/user_type', locals: { is_current_user: is_current_user })
  end

  it 'renders frontend placeholder' do
    expect(rendered).to have_selector "#js-user-type[data-user-type='regular']"
    expect(rendered).to have_selector "#js-user-type[data-is-current-user='false']"
  end

  it 'renders loading icon' do
    expect(rendered).to have_selector '#js-user-type .gl-spinner-container.gl-mb-6.gl-inline-block'
    expect(rendered).to have_selector '.gl-spinner-md'
  end

  context 'when user is current user' do
    let_it_be(:is_current_user) { true }

    it 'renders frontend placeholder' do
      expect(rendered).to have_selector "#js-user-type[data-is-current-user='true']"
    end
  end
end
