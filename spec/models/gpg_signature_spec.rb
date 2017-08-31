require 'rails_helper'

RSpec.describe GpgSignature do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:gpg_key) }
  end

  describe 'validation' do
    subject { described_class.new }
    it { is_expected.to validate_presence_of(:commit_sha) }
    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_presence_of(:gpg_key_primary_keyid) }
  end

  describe '#commit' do
    it 'fetches the commit through the project' do
      commit_sha = '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33'
      project = create :project, :repository
      commit = create :commit, project: project
      gpg_signature = create :gpg_signature, commit_sha: commit_sha

      expect_any_instance_of(Project).to receive(:commit).with(commit_sha).and_return(commit)

      gpg_signature.commit
    end
  end
end
