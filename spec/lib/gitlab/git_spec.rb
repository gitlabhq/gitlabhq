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
end
