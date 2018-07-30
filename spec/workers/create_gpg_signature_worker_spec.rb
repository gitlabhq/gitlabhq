require 'spec_helper'

describe CreateGpgSignatureWorker do
  let(:project) { create(:project, :repository) }
  let(:commits) { project.repository.commits('HEAD', limit: 3).commits }
  let(:commit_shas) { commits.map(&:id) }

  context 'when GpgKey is found' do
    let(:gpg_commit) { instance_double(Gitlab::Gpg::Commit) }

    before do
      allow(Project).to receive(:find_by).with(id: project.id).and_return(project)
      allow(project).to receive(:commits_by).with(oids: commit_shas).and_return(commits)
    end

    subject { described_class.new.perform(commit_shas, project.id) }

    it 'calls Gitlab::Gpg::Commit#signature' do
      commits.each do |commit|
        expect(Gitlab::Gpg::Commit).to receive(:new).with(commit).and_return(gpg_commit).once
      end

      expect(gpg_commit).to receive(:signature).exactly(commits.size).times

      subject
    end

    it 'can recover from exception and continue the signature process' do
      allow(gpg_commit).to receive(:signature)
      allow(Gitlab::Gpg::Commit).to receive(:new).and_return(gpg_commit)
      allow(Gitlab::Gpg::Commit).to receive(:new).with(commits.first).and_raise(StandardError)

      expect(gpg_commit).to receive(:signature).exactly(2).times

      subject
    end
  end

  context 'when Commit is not found' do
    let(:nonexisting_commit_sha) { '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a34' }

    it 'does not raise errors' do
      expect { described_class.new.perform([nonexisting_commit_sha], project.id) }.not_to raise_error
    end
  end

  context 'when Project is not found' do
    let(:nonexisting_project_id) { -1 }

    it 'does not raise errors' do
      expect { described_class.new.perform(commit_shas, nonexisting_project_id) }.not_to raise_error
    end

    it 'does not call Gitlab::Gpg::Commit#signature' do
      expect_any_instance_of(Gitlab::Gpg::Commit).not_to receive(:signature)

      described_class.new.perform(commit_shas, nonexisting_project_id)
    end
  end
end
