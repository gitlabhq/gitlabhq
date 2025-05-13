# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/packages/index.html.haml', feature_category: :package_registry do
  include PackagesHelper

  let_it_be(:group) { build_stubbed(:group) }

  subject { rendered }

  before do
    assign(:group, group)
  end

  it 'renders vue entrypoint' do
    render

    expect(rendered).to have_selector('#js-vue-packages-list')
  end

  it 'sets npm group url' do
    render

    expect(rendered).to have_selector(
      "[data-npm-group-url=\"#{package_registry_group_url(group.id, :npm)}\"]"
    )
  end

  describe 'settings path' do
    context 'without permission' do
      before do
        allow(view).to receive(:show_group_package_registry_settings).and_return(false)
      end

      it 'sets empty settings path' do
        render

        expect(rendered).to have_selector('[data-settings-path=""]')
      end
    end

    context 'with permission' do
      before do
        allow(view).to receive(:show_group_package_registry_settings).and_return(true)
      end

      it 'sets group settings path' do
        render

        expect(rendered).to have_selector(
          "[data-settings-path=\"#{group_settings_packages_and_registries_path(group)}\"]"
        )
      end
    end
  end
end
