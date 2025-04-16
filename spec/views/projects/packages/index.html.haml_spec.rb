# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/packages/packages/index.html.haml', feature_category: :package_registry do
  include PackagesHelper

  let_it_be(:group) { build_stubbed(:group) }
  let_it_be(:project) { build(:project, namespace: group, group: group) }

  subject { rendered }

  before do
    assign(:project, project)
  end

  it 'renders vue entrypoint' do
    render

    expect(rendered).to have_selector('#js-vue-packages-list')
  end

  it 'sets npm group url' do
    render

    expect(rendered).to have_selector(
      "[data-npm-group-url=\"#{package_registry_group_url(project.group&.id, :npm)}\"]"
    )
  end

  describe 'settings path' do
    context 'without permission' do
      before do
        allow(view).to receive(:show_package_registry_settings).and_return(false)
      end

      it 'sets empty settings path' do
        render

        expect(rendered).to have_selector('[data-settings-path=""]')
      end
    end

    context 'with permission' do
      before do
        allow(view).to receive(:show_package_registry_settings).and_return(true)
      end

      it 'sets project settings path' do
        render
        expect(rendered).to have_selector(
          "[data-settings-path=\"#{project_settings_packages_and_registries_path(project)}#package-registry-settings\"]"
        )
      end
    end
  end
end
