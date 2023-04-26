# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixImportSourcesOnApplicationSettingsAfterPhabricatorRemoval, feature_category: :importers do
  let(:settings) { table(:application_settings) }
  let(:import_sources) { %w[github git bitbucket bitbucket_server] }

  describe "#up" do
    shared_examples 'fixes import_sources on application_settings' do
      it 'ensures YAML is stored' do
        record = settings.create!(import_sources: data)

        migrate!

        expect(record.reload.import_sources).to start_with('---')
        expect(ApplicationSetting.last.import_sources).to eq(import_sources)
      end
    end

    context 'when import_sources is a String' do
      let(:data) { import_sources.to_s }

      it_behaves_like 'fixes import_sources on application_settings'
    end

    context 'when import_sources is already YAML' do
      let(:data) { import_sources.to_yaml }

      it_behaves_like 'fixes import_sources on application_settings'
    end
  end
end
