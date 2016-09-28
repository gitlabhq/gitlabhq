require 'spec_helper'

describe RepositoryImportWorker do
  let(:project) { create(:project) }

  subject { described_class.new }

  describe '#perform' do
    context 'when the import was successful' do
      it 'imports a project' do
        expect_any_instance_of(Projects::ImportService).to receive(:execute).
          and_return({ status: :ok })

        expect_any_instance_of(Repository).to receive(:expire_emptiness_caches)
        expect_any_instance_of(Project).to receive(:import_finish)

        subject.perform(project.id)
      end
    end

    context 'when the import has failed' do
      it 'hide the credentials that were used in the import URL' do
        error = %Q(remote: Not Found fatal: repository 'https://user:pass@test.com/root/repoC.git/' not found )
        expect_any_instance_of(Projects::ImportService).to receive(:execute).
          and_return({ status: :error, message: error })

        subject.perform(project.id)

        expect(project.reload.import_error).to include("https://*****:*****@test.com/root/repoC.git/")
      end
    end
  end
end
