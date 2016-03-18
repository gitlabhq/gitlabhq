require 'spec_helper'

describe RepositoryImportWorker do
  let(:project) { create(:project) }

  subject { described_class.new }

  describe '#perform' do
    it 'imports a project' do
      expect_any_instance_of(Projects::ImportService).to receive(:execute).
        and_return({ status: :ok })

      expect_any_instance_of(Repository).to receive(:expire_emptiness_caches)
      expect_any_instance_of(Project).to receive(:import_finish)

      subject.perform(project.id)
    end
  end
end
