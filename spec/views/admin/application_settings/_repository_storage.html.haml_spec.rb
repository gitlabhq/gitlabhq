# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_repository_storage.html.haml' do
  let(:app_settings) { build(:application_setting, repository_storages_weighted: repository_storages_weighted) }

  before do
    stub_storage_settings({ 'default': {}, 'mepmep': {}, 'foobar': {} })
    assign(:application_setting, app_settings)
  end

  context 'additional storage config' do
    let(:repository_storages_weighted) do
      {
        'default' => 100,
        'mepmep' => 50
      }
    end

    it 'lists them all' do
      render

      Gitlab.config.repositories.storages.keys.each do |storage_name|
        expect(rendered).to have_content(storage_name)
      end

      expect(rendered).to have_content('foobar')
    end
  end

  context 'fewer storage configs' do
    let(:repository_storages_weighted) do
      {
        'default' => 100,
        'mepmep' => 50,
        'something_old' => 100
      }
    end

    it 'lists only configured storages' do
      render

      Gitlab.config.repositories.storages.keys.each do |storage_name|
        expect(rendered).to have_content(storage_name)
      end

      expect(rendered).not_to have_content('something_old')
    end
  end
end
