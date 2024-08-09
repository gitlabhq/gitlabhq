# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/fullscreen' do
  let_it_be(:template) { 'layouts/fullscreen' }

  let_it_be(:user) { create(:user) }

  before do
    allow(view).to receive(:current_user_mode).and_return(Gitlab::Auth::CurrentUserMode.new(user))
  end

  it 'renders a flex container' do
    render

    expect(rendered).to have_selector(".gl--flex-full.gl-h-full")
    expect(rendered).to have_selector(".gl--flex-full.gl-w-full")
  end

  it 'renders flash container' do
    render

    expect(view).to render_template("layouts/_flash")
    expect(rendered).to have_selector(".flash-container.flash-container-no-margin")
  end

  it_behaves_like 'a layout which reflects the application color mode setting'
  it_behaves_like 'a layout which reflects the preferred language'
end
