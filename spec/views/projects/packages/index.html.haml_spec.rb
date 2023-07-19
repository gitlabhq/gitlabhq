# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/packages/packages/index.html.haml', feature_category: :package_registry do
  let_it_be(:project) { build(:project) }

  subject { rendered }

  before do
    assign(:project, project)
  end

  it 'renders vue entrypoint' do
    render

    expect(rendered).to have_selector('#js-vue-packages-list')
  end

  describe 'settings path' do
    it 'without permission sets empty settings path' do
      allow(view).to receive(:show_package_registry_settings).and_return(false)

      render

      expect(rendered).to have_selector('[data-settings-path=""]')
    end

    it 'with permission sets project settings path' do
      allow(view).to receive(:show_package_registry_settings).and_return(true)

      render

      expect(rendered).to have_selector(
        "[data-settings-path=\"#{project_settings_packages_and_registries_path(project)}\"]"
      )
    end
  end

  describe 'can_delete_packages' do
    it 'without permission sets empty settings path' do
      allow(view).to receive(:can_delete_packages?).and_return(false)

      render

      expect(rendered).to have_selector('[data-can-delete-packages="false"]')
    end

    it 'with permission sets project settings path' do
      allow(view).to receive(:can_delete_packages?).and_return(true)

      render

      expect(rendered).to have_selector('[data-can-delete-packages="true"]')
    end
  end
end
