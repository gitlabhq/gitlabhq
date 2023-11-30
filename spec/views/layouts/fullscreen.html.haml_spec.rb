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

  it_behaves_like 'a layout which reflects the application theme setting'
  it_behaves_like 'a layout which reflects the preferred language'

  describe 'sidebar' do
    context 'when nav is set' do
      before do
        allow(view).to receive(:nav).and_return("admin")
        render
      end

      it 'renders the sidebar' do
        expect(rendered).to render_template("layouts/nav/sidebar/_admin")
        expect(rendered).to have_selector("aside.nav-sidebar")
      end

      it 'adds the proper classes' do
        expect(rendered).to have_selector(".layout-page.gl-mt-0\\!")
      end
    end

    describe 'when nav is not set' do
      before do
        allow(view).to receive(:nav).and_return(nil)
        render
      end

      it 'does not render the sidebar' do
        expect(rendered).not_to render_template("layouts/nav/sidebar/_admin")
        expect(rendered).not_to have_selector("aside.nav-sidebar")
      end

      it 'not add classes' do
        expect(rendered).not_to have_selector(".layout-page.gl-mt-0\\!")
      end
    end
  end
end
