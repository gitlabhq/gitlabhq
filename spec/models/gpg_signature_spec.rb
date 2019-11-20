# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GpgSignature do
  let(:commit_sha) { '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33' }
  let!(:project) { create(:project, :repository, path: 'sample-project') }
  let!(:commit) { create(:commit, project: project, sha: commit_sha) }
  let(:gpg_signature) { create(:gpg_signature, commit_sha: commit_sha) }
  let(:gpg_key) { create(:gpg_key) }
  let(:gpg_key_subkey) { create(:gpg_key_subkey) }

  it_behaves_like 'having unique enum values'

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:gpg_key) }
    it { is_expected.to belong_to(:gpg_key_subkey) }
  end

  describe 'validation' do
    subject { described_class.new }

    it { is_expected.to validate_presence_of(:commit_sha) }
    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_presence_of(:gpg_key_primary_keyid) }
  end

  describe '.safe_create!' do
    let(:attributes) do
      {
        commit_sha: commit_sha,
        project: project,
        gpg_key_primary_keyid: gpg_key.keyid
      }
    end

    it 'finds a signature by commit sha if it existed' do
      gpg_signature

      expect(described_class.safe_create!(commit_sha: commit_sha)).to eq(gpg_signature)
    end

    it 'creates a new signature if it was not found' do
      expect { described_class.safe_create!(attributes) }.to change { described_class.count }.by(1)
    end

    it 'assigns the correct attributes when creating' do
      signature = described_class.safe_create!(attributes)

      expect(signature.project).to eq(project)
      expect(signature.commit_sha).to eq(commit_sha)
      expect(signature.gpg_key_primary_keyid).to eq(gpg_key.keyid)
    end

    it 'does not raise an error in case of a race condition' do
      expect(described_class).to receive(:find_or_create_by).and_raise(ActiveRecord::RecordNotUnique)
      allow(described_class).to receive(:find_or_create_by).and_call_original

      described_class.safe_create!(attributes)
    end
  end

  describe '.by_commit_sha scope' do
    let(:gpg_key) { create(:gpg_key, key: GpgHelpers::User2.public_key) }
    let!(:another_gpg_signature) { create(:gpg_signature, gpg_key: gpg_key) }

    it 'returns all gpg signatures by sha' do
      expect(described_class.by_commit_sha(commit_sha)).to eq([gpg_signature])
      expect(
        described_class.by_commit_sha([commit_sha, another_gpg_signature.commit_sha])
      ).to contain_exactly(gpg_signature, another_gpg_signature)
    end
  end

  describe '#commit' do
    it 'fetches the commit through the project' do
      expect_next_instance_of(Project) do |instance|
        expect(instance).to receive(:commit).with(commit_sha).and_return(commit)
      end

      gpg_signature.commit
    end
  end

  describe '#gpg_key=' do
    it 'supports the assignment of a GpgKey' do
      gpg_signature = create(:gpg_signature, gpg_key: gpg_key)

      expect(gpg_signature.gpg_key).to be_an_instance_of(GpgKey)
    end

    it 'supports the assignment of a GpgKeySubkey' do
      gpg_signature = create(:gpg_signature, gpg_key: gpg_key_subkey)

      expect(gpg_signature.gpg_key).to be_an_instance_of(GpgKeySubkey)
    end

    it 'clears gpg_key and gpg_key_subkey_id when passing nil' do
      gpg_signature.update_attribute(:gpg_key, nil)

      expect(gpg_signature.gpg_key_id).to be_nil
      expect(gpg_signature.gpg_key_subkey_id).to be_nil
    end
  end

  describe '#gpg_commit' do
    context 'when commit does not exist' do
      it 'returns nil' do
        allow(gpg_signature).to receive(:commit).and_return(nil)

        expect(gpg_signature.gpg_commit).to be_nil
      end
    end

    context 'when commit exists' do
      it 'returns an instance of Gitlab::Gpg::Commit' do
        allow(gpg_signature).to receive(:commit).and_return(commit)

        expect(gpg_signature.gpg_commit).to be_an_instance_of(Gitlab::Gpg::Commit)
      end
    end
  end
end
