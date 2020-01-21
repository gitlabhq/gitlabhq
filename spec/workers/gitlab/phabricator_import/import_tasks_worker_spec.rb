# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::PhabricatorImport::ImportTasksWorker do
  describe '#perform' do
    it 'calls the correct importer' do
      project = create(:project, :import_started, import_url: "https://the.phab.ulr")
      fake_importer = instance_double(Gitlab::PhabricatorImport::Issues::Importer)

      expect(Gitlab::PhabricatorImport::Issues::Importer).to receive(:new).with(project).and_return(fake_importer)
      expect(fake_importer).to receive(:execute)

      described_class.new.perform(project.id)
    end
  end
end
