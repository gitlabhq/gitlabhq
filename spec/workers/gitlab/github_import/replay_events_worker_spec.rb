# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::ReplayEventsWorker, feature_category: :importers do
  let_it_be(:project) { create(:project, import_state: create(:import_state, :started)) }
  let(:client) { instance_double(Gitlab::GithubImport::Client) }

  let(:worker) { described_class.new }

  describe '#import' do
    it 'call replay events importer' do
      hash = {
        'issuable_iid' => 1,
        'issuable_type' => 'Issue'
      }

      expect_next_instance_of(Gitlab::GithubImport::Importer::ReplayEventsImporter,
        an_instance_of(Gitlab::GithubImport::Representation::ReplayEvent), project, client) do |importer|
        expect(importer).to receive(:execute)
      end

      expect(Gitlab::GithubImport::ObjectCounter).not_to receive(:increment)

      worker.import(project, client, hash)
    end
  end

  describe '#object_type' do
    it { expect(worker.object_type).to eq(:replay_event) }
  end
end
