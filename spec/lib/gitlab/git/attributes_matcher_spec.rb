require 'spec_helper'

describe Gitlab::Git::AttributesMatcher do
  let(:project) { create(:project, :repository) }
  let(:repo) { project.repository }
  let(:ref) { 'lfs' }

  subject { described_class.new(repo, ref) }

  describe '#matches_filter?' do
    it 'is truthy if filter matches path' do
      expect(subject.matches_filter?('large_file.lfs', 'lfs')).to be_truthy
    end

    it "is falsey if filter doesn't match path" do
      expect(subject.matches_filter?('small_file.txt', 'lfs')).to be_falsey
    end
  end

  describe '#includes?' do
    it 'is truthy if key evalutes true' do
      expect(subject.includes?('large_file.lfs', 'merge')).to be_truthy
    end

    it "is falsey if key evalues false" do
      expect(subject.includes?('large_file.lfs', 'text')).to be_falsey
    end

    it "is falsey if key is missing" do
      expect(subject.includes?('small_file.txt', 'merge')).to be_falsey
    end
  end
end
