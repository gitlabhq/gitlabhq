require 'spec_helper'

describe BitbucketServer::Representation::Comment do
  let(:activities) { JSON.parse(fixture_file('importers/bitbucket_server/activities.json'))['values'] }
  let(:comment) { activities.first }

  subject { described_class.new(comment) }

  describe '#id' do
    it { expect(subject.id).to eq(9) }
  end

  describe '#author_username' do
    it { expect(subject.author_username).to eq('root' ) }
  end

  describe '#author_email' do
    it { expect(subject.author_email).to eq('test.user@example.com' ) }
  end

  describe '#note' do
    it { expect(subject.note).to eq('is this a new line?') }
  end

  describe '#created_at' do
    it { expect(subject.created_at).to be_a(Time) }
  end

  describe '#updated_at' do
    it { expect(subject.created_at).to be_a(Time) }
  end

  describe '#comments' do
    it { expect(subject.comments.count).to eq(4) }
    it { expect(subject.comments).to all( be_a(described_class) ) }
    it { expect(subject.comments.map(&:note)).to match_array(["Hello world", "Ok", "hello", "hi"]) }
  end
end
