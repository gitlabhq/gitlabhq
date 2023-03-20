# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreateCommitSignatureWorker, feature_category: :source_code_management do
  let(:project) { create(:project, :repository) }
  let(:commits) { project.repository.commits('HEAD', limit: 3).commits }
  let(:commit_shas) { commits.map(&:id) }
  let(:gpg_commit) { instance_double(Gitlab::Gpg::Commit) }
  let(:x509_commit) { instance_double(Gitlab::X509::Commit) }

  before do
    allow(Project).to receive(:find_by).with({ id: project.id }).and_return(project)
    allow(project).to receive(:commits_by).with({ oids: commit_shas }).and_return(commits)
  end

  subject { described_class.new.perform(commit_shas, project.id) }

  context 'when a signature is found' do
    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [commit_shas, project.id] }

      before do
        # Removing the stub which can cause bugs for multiple calls to
        # Project#commits_by.
        allow(project).to receive(:commits_by).and_call_original

        # Making sure it still goes through all the perform execution.
        allow_next_instance_of(::Commit) do |commit|
          allow(commit).to receive(:signature_type).and_return(:PGP)
        end

        allow_next_instance_of(::Gitlab::Gpg::Commit) do |gpg|
          expect(gpg).to receive(:signature).once.and_call_original
        end
      end
    end

    it 'calls Gitlab::Gpg::Commit#signature' do
      commits.each do |commit|
        allow(commit).to receive(:signature_type).and_return(:PGP)
        expect(Gitlab::Gpg::Commit).to receive(:new).with(commit).and_return(gpg_commit).once
      end

      expect(gpg_commit).to receive(:signature).exactly(commits.size).times

      subject
    end

    it 'can recover from exception and continue the signature process' do
      allow(gpg_commit).to receive(:signature)
      allow(Gitlab::Gpg::Commit).to receive(:new).and_return(gpg_commit)
      allow(Gitlab::Gpg::Commit).to receive(:new).with(commits.first).and_raise(StandardError)

      allow(commits[1]).to receive(:signature_type).and_return(:PGP)
      allow(commits[2]).to receive(:signature_type).and_return(:PGP)

      expect(gpg_commit).to receive(:signature).twice

      subject
    end

    it 'calls Gitlab::X509::Commit#signature' do
      commits.each do |commit|
        allow(commit).to receive(:signature_type).and_return(:X509)
        expect(Gitlab::X509::Commit).to receive(:new).with(commit).and_return(x509_commit).once
      end

      expect(x509_commit).to receive(:signature).exactly(commits.size).times

      subject
    end

    it 'can recover from exception and continue the X509 signature process' do
      allow(x509_commit).to receive(:signature)
      allow(Gitlab::X509::Commit).to receive(:new).and_return(x509_commit)
      allow(Gitlab::X509::Commit).to receive(:new).with(commits.first).and_raise(StandardError)

      allow(commits[1]).to receive(:signature_type).and_return(:X509)
      allow(commits[2]).to receive(:signature_type).and_return(:X509)

      expect(x509_commit).to receive(:signature).twice

      subject
    end
  end

  context 'handles when a string is passed in for the commit SHA' do
    let(:commit_shas) { super().first }

    before do
      allow(project).to receive(:commits_by).with(oids: [commit_shas]).and_return(commits)
      allow(commits.first).to receive(:signature_type).and_return(:PGP)
    end

    it 'creates a signature once' do
      allow(Gitlab::Gpg::Commit).to receive(:new).with(commits.first).and_return(gpg_commit)

      expect(gpg_commit).to receive(:signature).once

      subject
    end
  end

  context 'when Commit is not found' do
    let(:nonexisting_commit_sha) { '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a34' }
    let(:commit_shas) { [nonexisting_commit_sha] }

    it 'does not raise errors' do
      expect { described_class.new.perform(commit_shas, project.id) }.not_to raise_error
    end
  end

  context 'when Project is not found' do
    let(:commits) { [] }
    let(:project) { double(id: non_existing_record_id) }

    it 'does not raise errors' do
      expect { subject }.not_to raise_error
    end

    it 'does not call Gitlab::Gpg::Commit#signature' do
      expect_any_instance_of(Gitlab::Gpg::Commit).not_to receive(:signature)

      subject
    end

    it 'does not call Gitlab::X509::Commit#signature' do
      expect_any_instance_of(Gitlab::X509::Commit).not_to receive(:signature)

      subject
    end
  end

  context 'fetching signatures' do
    before do
      commits.each do |commit|
        allow(commit).to receive(:signature_type).and_return(type)
      end
    end

    context 'X509' do
      let(:type) { :X509 }

      it 'performs a single query for commit signatures' do
        expect(CommitSignatures::X509CommitSignature).to receive(:by_commit_sha).with(commit_shas).once.and_return([])

        subject
      end
    end

    context 'PGP' do
      let(:type) { :PGP }

      it 'performs a single query for commit signatures' do
        expect(CommitSignatures::GpgSignature).to receive(:by_commit_sha).with(commit_shas).once.and_return([])

        subject
      end
    end
  end
end
