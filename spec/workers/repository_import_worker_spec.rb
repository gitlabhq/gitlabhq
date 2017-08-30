require 'spec_helper'

describe RepositoryImportWorker do
  let(:project) { create(:project, :import_scheduled) }

  subject { described_class.new }

  describe '#perform' do
    context 'when the import was successful' do
      it 'imports a project' do
        expect_any_instance_of(Projects::ImportService).to receive(:execute)
          .and_return({ status: :ok })

        expect_any_instance_of(Repository).to receive(:expire_emptiness_caches)
        expect_any_instance_of(Project).to receive(:import_finish)

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
        end.to raise_error(RepositoryImportWorker::ImportError, error)
        expect(project.reload.import_jid).not_to be_nil
      end
    end

    context 'with unexpected error' do
      it 'marks import as failed' do
        allow_any_instance_of(Projects::ImportService).to receive(:execute).and_raise(RuntimeError)

        expect do
          subject.perform(project.id)
        end.to raise_error(RepositoryImportWorker::ImportError)
        expect(project.reload.import_status).to eq('failed')
      end
    end
  end
end
