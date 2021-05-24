# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::RemoteRepository, :seed_helper do
  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '', 'group/project') }

  subject { described_class.new(repository) }

  describe '#empty?' do
    using RSpec::Parameterized::TableSyntax

    where(:repository, :result) do
      Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '', 'group/project')       | false
      Gitlab::Git::Repository.new('default', 'does-not-exist.git', '', 'group/project') | true
    end

    with_them do
      it { expect(subject.empty?).to eq(result) }
    end
  end

  describe '#commit_id' do
    it 'returns an OID if the revision exists' do
      expect(subject.commit_id('v1.0.0')).to eq('6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9')
    end

    it 'is nil when the revision does not exist' do
      expect(subject.commit_id('does-not-exist')).to be_nil
    end
  end

  describe '#branch_exists?' do
    using RSpec::Parameterized::TableSyntax

    where(:branch, :result) do
      'master'         | true
      'does-not-exist' | false
    end

    with_them do
      it { expect(subject.branch_exists?(branch)).to eq(result) }
    end
  end

  describe '#same_repository?' do
    using RSpec::Parameterized::TableSyntax

    where(:other_repository, :result) do
      repository                                                                                      | true
      Gitlab::Git::Repository.new(repository.storage, repository.relative_path, '', 'group/project')  | true
      Gitlab::Git::Repository.new('broken', TEST_REPO_PATH, '', 'group/project')                      | false
      Gitlab::Git::Repository.new(repository.storage, 'wrong/relative-path.git', '', 'group/project') | false
      Gitlab::Git::Repository.new('broken', 'wrong/relative-path.git', '', 'group/project')           | false
    end

    with_them do
      it { expect(subject.same_repository?(other_repository)).to eq(result) }
    end
  end
end
