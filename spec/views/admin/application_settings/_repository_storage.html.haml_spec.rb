# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_repository_storage.html.haml' do
  let(:app_settings) { create(:application_setting) }
  let(:repository_storages_weighted_attributes) { [:repository_storages_weighted_default, :repository_storages_weighted_mepmep, :repository_storages_weighted_foobar]}
  let(:repository_storages_weighted) do
    {
      "default" => 100,
      "mepmep" => 50
    }
  end

  before do
    allow(app_settings).to receive(:repository_storages_weighted).and_return(repository_storages_weighted)
    allow(app_settings).to receive(:repository_storages_weighted_mepmep).and_return(100)
    allow(app_settings).to receive(:repository_storages_weighted_foobar).and_return(50)
    assign(:application_setting, app_settings)
    allow(ApplicationSetting).to receive(:repository_storages_weighted_attributes).and_return(repository_storages_weighted_attributes)
  end

  context 'when multiple storages are available' do
    it 'lists them all' do
      render

      # lists storages that are saved with weights
      repository_storages_weighted.each do |storage_name, storage_weight|
        expect(rendered).to have_content(storage_name)
      end

      # lists storage not saved with weight
      expect(rendered).to have_content('foobar')
    end
  end
end
