# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Importers::PullRequestNotesImporter, feature_category: :importers do
  let_it_be(:project) do
    create(:project, :import_started,
      import_data_attributes: {
        credentials: { 'base_uri' => 'http://bitbucket.org/', 'user' => 'bitbucket', 'password' => 'password' }
      }
    )
  end

  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  let(:hash) { { iid: merge_request.iid } }
  let(:importer_helper) { Gitlab::BitbucketImport::Importer.new(project) }

  subject(:importer) { described_class.new(project, hash) }

  before do
    allow(Gitlab::BitbucketImport::Importer).to receive(:new).and_return(importer_helper)
  end

  describe '#execute' do
    it 'calls Importer.import_pull_request_comments' do
      expect(importer_helper).to receive(:import_pull_request_comments).once

      importer.execute
    end

    context 'when the merge request does not exist' do
      let(:hash) { { iid: 'nonexistent' } }

      it 'does not call Importer.import_pull_request_comments' do
        expect(importer_helper).not_to receive(:import_pull_request_comments)

        importer.execute
      end
    end

    context 'when the merge request exists but not for this project' do
      let_it_be(:another_project) { create(:project) }

      before do
        merge_request.update!(source_project: another_project, target_project: another_project)
      end

      it 'does not call Importer.import_pull_request_comments' do
        expect(importer_helper).not_to receive(:import_pull_request_comments)

        importer.execute
      end
    end

    context 'when an error is raised' do
      before do
        allow(importer_helper).to receive(:import_pull_request_comments).and_raise(StandardError)
      end

      it 'tracks the failure and does not fail' do
        expect(Gitlab::Import::ImportFailureService).to receive(:track).once

        importer.execute
      end
    end
  end
end
