# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::PullRequestNotes::BaseImporter, feature_category: :importers do
  let_it_be(:project) do
    build_stubbed(:project, :repository, :import_started,
      import_data_attributes: {
        data: { 'project_key' => 'key', 'repo_slug' => 'slug' },
        credentials: { 'token' => 'token' }
      }
    )
  end

  let_it_be(:merge_request) { build_stubbed(:merge_request, source_project: project) }
  let_it_be(:importer_class) { Class.new(described_class) }
  let_it_be(:importer_instance) { importer_class.new(project, merge_request) }

  describe '#execute' do
    it { expect { importer_instance.execute({}) }.to raise_error(NotImplementedError) }
  end
end
