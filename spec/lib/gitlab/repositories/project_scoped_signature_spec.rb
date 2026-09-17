# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Repositories::ProjectScopedSignature, feature_category: :source_code_management do
  describe '#lazy_signature' do
    let_it_be(:project) { create(:project, :small_repo) }
    let_it_be(:gpg_key) { create(:gpg_key) }
    let_it_be(:gpg_commit) { create(:commit, project: project, sha: '1234567890abcdef1234567890abcdef12345678') }
    let_it_be(:ssh_commit) { create(:commit, project: project, sha: 'abcdef1234567890abcdef1234567890abcdef12') }

    let_it_be(:gpg_signature) do
      create(:gpg_signature, project: project, commit_sha: gpg_commit.sha, gpg_key: gpg_key,
        verification_status: :verified)
    end

    let_it_be(:ssh_signature) do
      create(:ssh_signature, project: project, commit_sha: ssh_commit.sha, verification_status: :verified)
    end

    before do
      allow(Gitlab::Git::Commit).to receive(:extract_signature_lazily).and_return(nil)
    end

    it 'resolves each signature type from its own batch group when both are batched together' do
      gpg = Gitlab::Gpg::Commit.new(gpg_commit)
      ssh = Gitlab::Ssh::Commit.new(ssh_commit)

      loaded_gpg = gpg.send(:lazy_signature).itself
      loaded_ssh = ssh.send(:lazy_signature).itself

      expect(loaded_gpg).to eq(gpg_signature)
      expect(loaded_gpg).to be_a(CommitSignatures::GpgSignature)

      expect(loaded_ssh).to eq(ssh_signature)
      expect(loaded_ssh).to be_a(CommitSignatures::SshSignature)
    end

    context 'with more than one commit of each type batched together' do
      let_it_be(:gpg_commit2) do
        create(:commit, project: project, sha: 'cafebabecafebabecafebabecafebabecafebabe')
      end

      let_it_be(:ssh_commit2) do
        create(:commit, project: project, sha: 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef')
      end

      let_it_be(:gpg_signature2) do
        create(:gpg_signature, project: project, commit_sha: gpg_commit2.sha, gpg_key: gpg_key,
          verification_status: :verified)
      end

      let_it_be(:ssh_signature2) do
        create(:ssh_signature, project: project, commit_sha: ssh_commit2.sha, verification_status: :verified)
      end

      it 'resolves every commit to its own signature and issues one query per type', :aggregate_failures do
        gpg1 = Gitlab::Gpg::Commit.new(gpg_commit)
        gpg2 = Gitlab::Gpg::Commit.new(gpg_commit2)
        ssh1 = Gitlab::Ssh::Commit.new(ssh_commit)
        ssh2 = Gitlab::Ssh::Commit.new(ssh_commit2)

        expect(CommitSignatures::GpgSignature).to receive(:by_commit_shas_and_project_ids).once.and_call_original
        expect(CommitSignatures::SshSignature).to receive(:by_commit_shas_and_project_ids).once.and_call_original

        loaded_gpg1 = gpg1.send(:lazy_signature).itself
        loaded_gpg2 = gpg2.send(:lazy_signature).itself
        loaded_ssh1 = ssh1.send(:lazy_signature).itself
        loaded_ssh2 = ssh2.send(:lazy_signature).itself

        expect(loaded_gpg1).to eq(gpg_signature)
        expect(loaded_gpg2).to eq(gpg_signature2)
        expect([loaded_gpg1, loaded_gpg2]).to all(be_a(CommitSignatures::GpgSignature))

        expect(loaded_ssh1).to eq(ssh_signature)
        expect(loaded_ssh2).to eq(ssh_signature2)
        expect([loaded_ssh1, loaded_ssh2]).to all(be_a(CommitSignatures::SshSignature))
      end
    end

    context 'when an X509 commit is batched alongside GPG and SSH commits' do
      let_it_be(:x509_commit) do
        create(:commit, project: project, sha: 'f00df00df00df00df00df00df00df00df00df00d')
      end

      let_it_be(:x509_signature) do
        create(:x509_commit_signature, project: project, commit_sha: x509_commit.sha, verification_status: :verified)
      end

      it 'leaves the sha-only X509 loader untouched and resolves each type correctly', :aggregate_failures do
        gpg = Gitlab::Gpg::Commit.new(gpg_commit)
        ssh = Gitlab::Ssh::Commit.new(ssh_commit)
        x509 = Gitlab::X509::Commit.new(x509_commit)

        loaded_gpg = gpg.send(:lazy_signature).itself
        loaded_ssh = ssh.send(:lazy_signature).itself
        loaded_x509 = x509.send(:lazy_signature).itself

        expect(loaded_gpg).to eq(gpg_signature)
        expect(loaded_gpg).to be_a(CommitSignatures::GpgSignature)

        expect(loaded_ssh).to eq(ssh_signature)
        expect(loaded_ssh).to be_a(CommitSignatures::SshSignature)

        expect(loaded_x509).to eq(x509_signature)
        expect(loaded_x509).to be_a(CommitSignatures::X509CommitSignature)
      end
    end

    it 'does not cross-contaminate types across repeated lazy_signature calls', :aggregate_failures do
      gpg = Gitlab::Gpg::Commit.new(gpg_commit)
      ssh = Gitlab::Ssh::Commit.new(ssh_commit)

      first_gpg = gpg.send(:lazy_signature).itself
      first_ssh = ssh.send(:lazy_signature).itself
      second_gpg = gpg.send(:lazy_signature).itself
      second_ssh = ssh.send(:lazy_signature).itself

      expect(first_gpg).to eq(gpg_signature)
      expect(second_gpg).to eq(gpg_signature)
      expect([first_gpg, second_gpg]).to all(be_a(CommitSignatures::GpgSignature))

      expect(first_ssh).to eq(ssh_signature)
      expect(second_ssh).to eq(ssh_signature)
      expect([first_ssh, second_ssh]).to all(be_a(CommitSignatures::SshSignature))
    end
  end
end
