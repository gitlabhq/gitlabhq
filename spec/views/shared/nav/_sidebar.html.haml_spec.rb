# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/nav/_sidebar.html.haml' do
  let(:project) { build(:project, id: non_existing_record_id) }
  let(:context) { Sidebars::Projects::Context.new(current_user: nil, container: project) }
  let(:sidebar) { Sidebars::Projects::Panel.new(context) }

  before do
    assign(:project, project)
    assign(:sidebar, sidebar)

    allow(sidebar).to receive(:renderable_menus).and_return([])
  end

  context 'when sidebar has a scope menu' do
    it 'renders the scope menu' do
      render

      expect(rendered).to render_template('shared/nav/_scope_menu')
    end
  end

  context 'when sidebar does not have a scope menu' do
    let(:scope_menu_view_path) { 'shared/nav/' }
    let(:scope_menu_view_name) { 'scope_menu.html.haml' }
    let(:scope_menu_partial) { "#{scope_menu_view_path}_#{scope_menu_view_name}" }
    let(:content) { 'Custom test content' }

    context 'when sidebar has a custom scope menu partial defined' do
      it 'renders the custom partial' do
        allow(view).to receive(:scope_menu).and_return(nil)
        stub_template(scope_menu_partial => content)

        render

        expect(rendered).to have_text(content)
      end
    end
  end
end
