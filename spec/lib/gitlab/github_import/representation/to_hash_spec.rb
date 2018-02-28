require 'spec_helper'

describe Gitlab::GithubImport::Representation::ToHash do
  describe '#to_hash' do
    let(:user) { double(:user, attributes: { login: 'alice' }) }

    let(:issue) do
      double(
        :issue,
        attributes: { user: user, assignees: [user], number: 42 }
      )
    end

    let(:issue_hash) { issue.to_hash }

    before do
      user.extend(described_class)
      issue.extend(described_class)
    end

    it 'converts an object to a Hash' do
      expect(issue_hash).to be_an_instance_of(Hash)
    end

    it 'converts nested objects to Hashes' do
      expect(issue_hash[:user]).to eq({ login: 'alice' })
    end

    it 'converts Array values to Hashes' do
      expect(issue_hash[:assignees]).to eq([{ login: 'alice' }])
    end

    it 'keeps values as-is if they do not respond to #to_hash' do
      expect(issue_hash[:number]).to eq(42)
    end
  end
end
