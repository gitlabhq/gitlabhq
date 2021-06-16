# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ReseedRepositoryStoragesWeighted do
  let(:storages) { { "foo" => {}, "baz" => {} } }
  let(:application_settings) do
    table(:application_settings).tap do |klass|
      klass.class_eval do
        serialize :repository_storages
      end
    end
  end

  before do
    allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
  end

  let(:repository_storages) { ["foo"] }
  let!(:application_setting) { application_settings.create!(repository_storages: repository_storages) }

  context 'with empty repository_storages_weighted column' do
    it 'populates repository_storages_weighted properly' do
      migrate!

      expect(application_settings.find(application_setting.id).repository_storages_weighted).to eq({ "foo" => 100, "baz" => 0 })
    end
  end

  context 'with already-populated repository_storages_weighted column' do
    let(:existing_weights) { { "foo" => 100, "baz" => 50 } }

    it 'does not change repository_storages_weighted properly' do
      application_setting.repository_storages_weighted = existing_weights
      application_setting.save!

      migrate!

      expect(application_settings.find(application_setting.id).repository_storages_weighted).to eq(existing_weights)
    end
  end
end
