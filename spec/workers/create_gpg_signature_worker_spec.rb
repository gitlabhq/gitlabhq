require 'spec_helper'

describe CreateGpgSignatureWorker do
  let(:project) { create(:project, :repository) }

  context 'when GpgKey is found' do
    let(:commit_sha) { '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33' }

    it 'calls Gitlab::Gpg::Commit#signature' do
      commit = instance_double(Commit)
      gpg_commit = instance_double(Gitlab::Gpg::Commit)

      allow(Project).to receive(:find_by).with(id: project.id).and_return(project)
      allow(project).to receive(:commit).with(commit_sha).and_return(commit)

      expect(Gitlab::Gpg::Commit).to receive(:new).with(commit).and_return(gpg_commit)
      expect(gpg_commit).to receive(:signature)

      described_class.new.perform(commit_sha, project.id)
    end
  end

  context 'when Commit is not found' do
    let(:nonexisting_commit_sha) { '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a34' }

    it 'does not raise errors' do
      expect { described_class.new.perform(nonexisting_commit_sha, project.id) }.not_to raise_error
    end
  end

  context 'when Project is not found' do
    let(:nonexisting_project_id) { -1 }

    it 'does not raise errors' do
      expect { described_class.new.perform(anything, nonexisting_project_id) }.not_to raise_error
    end

    it 'does not call Gitlab::Gpg::Commit#signature' do
      expect_any_instance_of(Gitlab::Gpg::Commit).not_to receive(:signature)

      described_class.new.perform(anything, nonexisting_project_id)
    end
  end
end
