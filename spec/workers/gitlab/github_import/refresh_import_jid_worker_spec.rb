require 'spec_helper'

describe Gitlab::GithubImport::RefreshImportJidWorker do
  let(:worker) { described_class.new }

  describe '.perform_in_the_future' do
    it 'schedules a job in the future' do
      expect(described_class)
        .to receive(:perform_in)
        .with(1.minute.to_i, 10, '123')

      described_class.perform_in_the_future(10, '123')
    end
  end

  describe '#perform' do
    let(:project) { create(:project, import_jid: '123abc') }

    context 'when the project does not exist' do
      it 'does nothing' do
        expect(Gitlab::SidekiqStatus)
          .not_to receive(:running?)

        worker.perform(-1, '123')
      end
    end

    context 'when the job is running' do
      it 'refreshes the import JID and reschedules itself' do
        allow(worker)
          .to receive(:find_project)
          .with(project.id)
          .and_return(project)

        expect(Gitlab::SidekiqStatus)
          .to receive(:running?)
          .with('123')
          .and_return(true)

        expect(project)
          .to receive(:refresh_import_jid_expiration)

        expect(worker.class)
          .to receive(:perform_in_the_future)
          .with(project.id, '123')

        worker.perform(project.id, '123')
      end
    end

    context 'when the job is no longer running' do
      it 'returns' do
        allow(worker)
          .to receive(:find_project)
          .with(project.id)
          .and_return(project)

        expect(Gitlab::SidekiqStatus)
          .to receive(:running?)
          .with('123')
          .and_return(false)

        expect(project)
          .not_to receive(:refresh_import_jid_expiration)

        worker.perform(project.id, '123')
      end
    end
  end

  describe '#find_project' do
    it 'returns a Project' do
      project = create(:project, import_status: 'started')

      expect(worker.find_project(project.id)).to be_an_instance_of(Project)
    end

    it 'only selects the import JID field' do
      project = create(:project, import_status: 'started', import_jid: '123abc')

      expect(worker.find_project(project.id).attributes)
        .to eq({ 'id' => nil, 'import_jid' => '123abc' })
    end

    it 'returns nil for a project for which the import process failed' do
      project = create(:project, import_status: 'failed')

      expect(worker.find_project(project.id)).to be_nil
    end

    it 'returns nil for a non-existing project' do
      expect(worker.find_project(-1)).to be_nil
    end
  end
end
