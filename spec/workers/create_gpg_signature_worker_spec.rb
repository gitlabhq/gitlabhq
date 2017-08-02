require 'spec_helper'

describe CreateGpgSignatureWorker do
  context 'when GpgKey is found' do
    it 'calls Commit#signature' do
      commit_sha = '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33'
      project = create :empty_project
      commit = instance_double(Commit)

      allow(Project).to receive(:find_by).with(id: project.id).and_return(project)
      allow(project).to receive(:commit).with(commit_sha).and_return(commit)

      expect(commit).to receive(:signature)

      described_class.new.perform(commit_sha, project.id)
    end
  end

  context 'when Commit is not found' do
    let(:nonexisting_commit_sha) { 'bogus' }
    let(:project) { create :empty_project }

    it 'does not raise errors' do
      expect { described_class.new.perform(nonexisting_commit_sha, project.id) }.not_to raise_error
    end

    it 'does not call Commit#signature' do
      expect_any_instance_of(Commit).not_to receive(:signature)

      described_class.new.perform(nonexisting_commit_sha, project.id)
    end
  end

  context 'when Project is not found' do
    let(:nonexisting_project_id) { -1 }

    it 'does not raise errors' do
      expect { described_class.new.perform(anything, nonexisting_project_id) }.not_to raise_error
    end

    it 'does not call Commit#signature' do
      expect_any_instance_of(Commit).not_to receive(:signature)

      described_class.new.perform(anything, nonexisting_project_id)
    end
  end
end
