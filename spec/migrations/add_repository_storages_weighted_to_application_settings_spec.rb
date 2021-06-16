# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddRepositoryStoragesWeightedToApplicationSettings, :migration do
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

  let(:application_setting) { application_settings.create! }
  let(:repository_storages) { ["foo"] }

  it 'populates repository_storages_weighted properly' do
    application_setting.repository_storages = repository_storages
    application_setting.save!

    migrate!

    expect(application_settings.find(application_setting.id).repository_storages_weighted).to eq({ "foo" => 100, "baz" => 0 })
  end
end
