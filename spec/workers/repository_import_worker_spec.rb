require 'spec_helper'

describe RepositoryImportWorker do
  describe 'modules' do
    it 'includes ProjectImportOptions' do
      expect(described_class).to include_module(ProjectImportOptions)
    end
  end

  describe '#perform' do
    let(:project) { create(:project, :import_scheduled) }

    context 'when worker was reset without cleanup' do
      it 'imports the project successfully' do
        jid = '12345678'
        started_project = create(:project)

        create(:import_state, :started, project: started_project, jid: jid)

        allow(subject).to receive(:jid).and_return(jid)

        expect_any_instance_of(Projects::ImportService).to receive(:execute)
          .and_return({ status: :ok })

        # Works around https://github.com/rspec/rspec-mocks/issues/910
        expect(Project).to receive(:find).with(project.id).and_return(project)
        expect(project.repository).to receive(:expire_emptiness_caches)
        expect(project.wiki.repository).to receive(:expire_emptiness_caches)
        expect(project).to receive(:import_finish)

        subject.perform(project.id)
      end
    end

    context 'when the import was successful' do
      it 'imports a project' do
        expect_any_instance_of(Projects::ImportService).to receive(:execute)
          .and_return({ status: :ok })

        # Works around https://github.com/rspec/rspec-mocks/issues/910
        expect(Project).to receive(:find).with(project.id).and_return(project)
        expect(project.repository).to receive(:expire_emptiness_caches)
        expect(project.wiki.repository).to receive(:expire_emptiness_caches)
        expect(project).to receive(:import_finish)

        subject.perform(project.id)
      end
    end

    context 'when project is a mirror' do
      let(:project) { create(:project, :mirror, :import_scheduled) }

      it 'adds mirror in front of the mirror scheduler queue' do
        expect_any_instance_of(Projects::ImportService).to receive(:execute)
          .and_return({ status: :ok })

        expect_any_instance_of(EE::Project).to receive(:force_import_job!)

        subject.perform(project.id)
      end
    end

    context 'when the import has failed' do
      it 'hide the credentials that were used in the import URL' do
        error = %q{remote: Not Found fatal: repository 'https://user:pass@test.com/root/repoC.git/' not found }

        project.update_attributes(import_jid: '123')
        expect_any_instance_of(Projects::ImportService).to receive(:execute).and_return({ status: :error, message: error })

        expect do
          subject.perform(project.id)
        end.to raise_error(RuntimeError, error)
        expect(project.reload.import_jid).not_to be_nil
      end

      it 'updates the error on Import/Export' do
        error = %q{remote: Not Found fatal: repository 'https://user:pass@test.com/root/repoC.git/' not found }

        project.update_attributes(import_jid: '123', import_type: 'gitlab_project')
        expect_any_instance_of(Projects::ImportService).to receive(:execute).and_return({ status: :error, message: error })

        expect do
          subject.perform(project.id)
        end.to raise_error(RuntimeError, error)

        expect(project.reload.import_error).not_to be_nil
      end
    end

    context 'when using an asynchronous importer' do
      it 'does not mark the import process as finished' do
        service = double(:service)

        allow(Projects::ImportService)
          .to receive(:new)
          .and_return(service)

        allow(service)
          .to receive(:execute)
          .and_return(true)

        allow(service)
          .to receive(:async?)
          .and_return(true)

        expect_any_instance_of(Project)
          .not_to receive(:import_finish)

        subject.perform(project.id)
      end
    end
  end
end
