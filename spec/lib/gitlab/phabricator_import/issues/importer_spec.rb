# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::PhabricatorImport::Issues::Importer do
  let(:project) { create(:project) }

  let(:response) do
    Gitlab::PhabricatorImport::Conduit::TasksResponse.new(
      Gitlab::PhabricatorImport::Conduit::Response
        .new(Gitlab::Json.parse(fixture_file('phabricator_responses/maniphest.search.json')))
    )
  end

  subject(:importer) { described_class.new(project, nil) }

  before do
    client = instance_double(Gitlab::PhabricatorImport::Conduit::Maniphest)
    allow(client).to receive(:tasks).and_return(response)
    allow(importer).to receive(:client).and_return(client)
  end

  describe '#execute' do
    it 'imports each task in the response' do
      response.tasks.each do |task|
        task_importer = instance_double(Gitlab::PhabricatorImport::Issues::TaskImporter)

        expect(task_importer).to receive(:execute)
        expect(Gitlab::PhabricatorImport::Issues::TaskImporter)
          .to receive(:new).with(project, task)
                .and_return(task_importer)
      end

      importer.execute
    end

    context 'stubbed task import' do
      before do
        # Stub out the actual importing so we don't perform aditional requests
        expect_next_instance_of(Gitlab::PhabricatorImport::Issues::TaskImporter) do |task_importer|
          allow(task_importer).to receive(:execute)
        end.at_least(1)
      end

      it 'schedules the next batch if there is one' do
        expect(Gitlab::PhabricatorImport::ImportTasksWorker)
          .to receive(:schedule).with(project.id, response.pagination.next_page)

        importer.execute
      end

      it 'does not reschedule when there is no next page' do
        allow(response.pagination).to receive(:has_next_page?).and_return(false)

        expect(Gitlab::PhabricatorImport::ImportTasksWorker)
          .not_to receive(:schedule)

        importer.execute
      end
    end
  end
end
