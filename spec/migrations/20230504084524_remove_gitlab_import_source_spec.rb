# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveGitlabImportSource, feature_category: :importers do
  let(:settings) { table(:application_settings) }
  let(:import_sources_with_gitlab) { %w[github git gitlab bitbucket bitbucket_server] }
  let(:import_sources_without_gitlab) { %w[github git bitbucket bitbucket_server] }

  describe "#up" do
    it 'removes gitlab and preserves existing valid import sources' do
      record = settings.create!(import_sources: import_sources_with_gitlab)

      migrate!

      expect(record.reload.import_sources).to start_with('---')

      expect(ApplicationSetting.last.import_sources).to eq(import_sources_without_gitlab)
    end
  end
end
