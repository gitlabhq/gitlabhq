# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git do
  let(:committer_email) { 'user@example.org' }
  let(:committer_name) { 'John Doe' }

  describe '.ref_name' do
    let(:ref) { Gitlab::Git::BRANCH_REF_PREFIX + "an_invalid_ref_\xE5" }

    subject(:ref_name) { described_class.ref_name(ref) }

    it 'ensure ref is a valid UTF-8 string' do
      expect(ref_name).to eq("an_invalid_ref_%E5")
    end

    context 'when ref contains characters \x80 - \xFF' do
      let(:ref) { Gitlab::Git::BRANCH_REF_PREFIX + "\x90" }

      it 'correctly converts it' do
        expect(ref_name).to eq("%90")
      end
    end

    context 'with different types' do
      using RSpec::Parameterized::TableSyntax

      where(:ref, :types, :result) do
        'refs/heads/master'          | 'tags|heads|remotes' | 'master'
        'refs/tags/v1.0'             | 'tags|heads|remotes' | 'v1.0'
        'refs/heads/master'          | 'heads'              | 'master'
        'refs/tags/v1.0'             | 'tags'               | 'v1.0'
        'refs/heads/master'          | 'tags'               | 'refs/heads/master'
        'refs/tags/v1.0'             | 'heads'              | 'refs/tags/v1.0'
        'refs/remotes/origin/master' | 'tags|heads|remotes' | 'origin/master'
        'refs/remotes/origin/master' | 'tags|heads'         | 'refs/remotes/origin/master'
      end

      with_them do
        subject(:ref_name) { described_class.ref_name(ref, types: types) }

        it { is_expected.to eq(result) }
      end
    end
  end

  describe '.commit_id?' do
    using RSpec::Parameterized::TableSyntax

    where(:sha, :result) do
      ''                                         | false
      'foobar'                                   | false
      '4b825dc'                                  | false
      'zzz25dc642cb6eb9a060e54bf8d69288fbee4904' | false

      '4b825dc642cb6eb9a060e54bf8d69288fbee4904' | true
      Gitlab::Git::SHA1_BLANK_SHA                | true
    end

    with_them do
      it 'returns the expected result' do
        expect(described_class.commit_id?(sha)).to eq(result)
      end
    end
  end

  describe '.shas_eql?' do
    using RSpec::Parameterized::TableSyntax

    where(:sha1, :sha2, :result) do
      sha           = RepoHelpers.sample_commit.id
      short_sha     = sha[0, Gitlab::Git::Commit::MIN_SHA_LENGTH]
      too_short_sha = sha[0, Gitlab::Git::Commit::MIN_SHA_LENGTH - 1]

      [
        [sha, sha,           true],
        [sha, short_sha,     true],
        [sha, sha.reverse,   false],
        [sha, too_short_sha, false],
        [sha, nil,           false],
        [nil, nil,           true]
      ]
    end

    with_them do
      it { expect(described_class.shas_eql?(sha1, sha2)).to eq(result) }

      it 'is commutative' do
        expect(described_class.shas_eql?(sha2, sha1)).to eq(result)
      end
    end
  end

  describe '.blank_ref?' do
    using RSpec::Parameterized::TableSyntax

    where(:sha, :result) do
      '4b825dc642cb6eb9a060e54bf8d69288fbee4904'                         | false
      '0000000000000000000000000000000000000000'                         | true
      '0000000000000000000000000000000000000000000000000000000000000000' | true
    end

    with_them do
      it 'returns the expected result' do
        expect(described_class.blank_ref?(sha)).to eq(result)
      end
    end
  end
end
