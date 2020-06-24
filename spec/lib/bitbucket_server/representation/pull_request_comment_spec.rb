# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BitbucketServer::Representation::PullRequestComment do
  let(:activities) { Gitlab::Json.parse(fixture_file('importers/bitbucket_server/activities.json'))['values'] }
  let(:comment) { activities.second }

  subject { described_class.new(comment) }

  describe '#id' do
    it { expect(subject.id).to eq(7) }
  end

  describe '#from_sha' do
    it { expect(subject.from_sha).to eq('c5f4288162e2e6218180779c7f6ac1735bb56eab') }
  end

  describe '#to_sha' do
    it { expect(subject.to_sha).to eq('a4c2164330f2549f67c13f36a93884cf66e976be') }
  end

  describe '#to?' do
    it { expect(subject.to?).to be_falsey }
  end

  describe '#from?' do
    it { expect(subject.from?).to be_truthy }
  end

  describe '#added?' do
    it { expect(subject.added?).to be_falsey }
  end

  describe '#removed?' do
    it { expect(subject.removed?).to be_falsey }
  end

  describe '#new_pos' do
    it { expect(subject.new_pos).to eq(11) }
  end

  describe '#old_pos' do
    it { expect(subject.old_pos).to eq(9) }
  end

  describe '#file_path' do
    it { expect(subject.file_path).to eq('CHANGELOG.md') }
  end
end
