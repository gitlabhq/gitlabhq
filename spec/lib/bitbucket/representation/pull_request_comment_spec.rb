# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Bitbucket::Representation::PullRequestComment, feature_category: :importers do
  describe '#iid' do
    it { expect(described_class.new('id' => 1).iid).to eq(1) }
  end

  describe '#file_path' do
    it { expect(described_class.new('inline' => { 'path' => '/path' }).file_path).to eq('/path') }
  end

  describe '#old_pos' do
    it { expect(described_class.new('inline' => { 'from' => 3 }).old_pos).to eq(3) }
  end

  describe '#new_pos' do
    it { expect(described_class.new('inline' => { 'to' => 3 }).new_pos).to eq(3) }
  end

  describe '#parent_id' do
    it { expect(described_class.new({ 'parent' => { 'id' => 2 } }).parent_id).to eq(2) }
    it { expect(described_class.new({}).parent_id).to be_nil }
  end

  describe '#inline?' do
    it { expect(described_class.new('inline' => {}).inline?).to be_truthy }
    it { expect(described_class.new({}).inline?).to be_falsey }
  end

  describe '#has_parent?' do
    it { expect(described_class.new('parent' => {}).has_parent?).to be_truthy }
    it { expect(described_class.new({}).has_parent?).to be_falsey }
  end

  describe '#deleted?' do
    it { expect(described_class.new('deleted' => true).deleted?).to be_truthy }
    it { expect(described_class.new('deleted' => false).deleted?).to be_falsey }
    it { expect(described_class.new({}).deleted?).to be_falsey }
  end
end
