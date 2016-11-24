require 'spec_helper'

describe Gitlab::Git, lib: true do
  let(:committer_email) { FFaker::Internet.email }

  # I have to remove periods from the end of the name
  # This happened when the user's name had a suffix (i.e. "Sr.")
  # This seems to be what git does under the hood. For example, this commit:
  #
  # $ git commit --author='Foo Sr. <foo@example.com>' -m 'Where's my trailing period?'
  #
  # results in this:
  #
  # $ git show --pretty
  # ...
  # Author: Foo Sr <foo@example.com>
  # ...
  let(:committer_name) { FFaker::Name.name.chomp("\.") }

  describe 'committer_hash' do
    it "returns a hash containing the given email and name" do
      committer_hash = Gitlab::Git::committer_hash(email: committer_email, name: committer_name)

      expect(committer_hash[:email]).to eq(committer_email)
      expect(committer_hash[:name]).to eq(committer_name)
      expect(committer_hash[:time]).to be_a(Time)
    end

    context 'when email is nil' do
      it "returns nil" do
        committer_hash = Gitlab::Git::committer_hash(email: nil, name: committer_name)

        expect(committer_hash).to be_nil
      end
    end

    context 'when name is nil' do
      it "returns nil" do
        committer_hash = Gitlab::Git::committer_hash(email: committer_email, name: nil)

        expect(committer_hash).to be_nil
      end
    end
  end
end
