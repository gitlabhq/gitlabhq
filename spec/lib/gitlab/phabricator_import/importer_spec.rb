# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::PhabricatorImport::Importer do
  it { expect(described_class).to be_async }

  it "acts like it's importing repositories" do
    expect(described_class).to be_imports_repository
  end

  describe '#execute' do
    let(:project) { create(:project, :import_scheduled) }

    subject(:importer) { described_class.new(project) }

    it 'sets a custom jid that will be kept up to date' do
      expect { importer.execute }.to change { project.import_state.reload.jid }
    end

    it 'starts importing tasks' do
      expect(Gitlab::PhabricatorImport::ImportTasksWorker).to receive(:schedule).with(project.id)

      importer.execute
    end

    it 'marks the import as failed when something goes wrong' do
      allow(importer).to receive(:schedule_first_tasks_page).and_raise('Stuff is broken')

      importer.execute

      expect(project.import_state).to be_failed
    end
  end
end
