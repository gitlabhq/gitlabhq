# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Git do
  let(:committer_email) { 'user@example.org' }
  let(:committer_name) { 'John Doe' }

  describe 'committer_hash' do
    it "returns a hash containing the given email and name" do
      committer_hash = described_class.committer_hash(email: committer_email, name: committer_name)

      expect(committer_hash[:email]).to eq(committer_email)
      expect(committer_hash[:name]).to eq(committer_name)
      expect(committer_hash[:time]).to be_a(Time)
    end

    context 'when email is nil' do
      it "returns nil" do
        committer_hash = described_class.committer_hash(email: nil, name: committer_name)

        expect(committer_hash).to be_nil
      end
    end

    context 'when name is nil' do
      it "returns nil" do
        committer_hash = described_class.committer_hash(email: committer_email, name: nil)

        expect(committer_hash).to be_nil
      end
    end
  end

  describe '.ref_name' do
    it 'ensure ref is a valid UTF-8 string' do
      utf8_invalid_ref = Gitlab::Git::BRANCH_REF_PREFIX + "an_invalid_ref_\xE5"

      expect(described_class.ref_name(utf8_invalid_ref)).to eq("an_invalid_ref_å")
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
      Gitlab::Git::BLANK_SHA                     | true
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
end
