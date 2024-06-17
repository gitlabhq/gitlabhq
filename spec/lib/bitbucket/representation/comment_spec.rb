# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Bitbucket::Representation::Comment, feature_category: :importers do
  describe '#author' do
    it { expect(described_class.new('user' => { 'uuid' => '{123}' }).author).to eq('{123}') }
    it { expect(described_class.new('user' => { 'nickname' => 'Ben' }).author).to be_nil }
    it { expect(described_class.new({}).author).to be_nil }
  end

  describe '#author_nickname' do
    it { expect(described_class.new('user' => { 'nickname' => 'Ben' }).author_nickname).to eq('Ben') }
    it { expect(described_class.new({}).author_nickname).to be_nil }
  end

  describe '#note' do
    it { expect(described_class.new('content' => { 'raw' => 'Text' }).note).to eq('Text') }
    it { expect(described_class.new({}).note).to be_nil }
  end

  describe '#created_at' do
    it { expect(described_class.new('created_on' => Date.today).created_at).to eq(Date.today) }
  end

  describe '#updated_at' do
    it { expect(described_class.new('updated_on' => Date.today).updated_at).to eq(Date.today) }
    it { expect(described_class.new('created_on' => Date.today).updated_at).to eq(Date.today) }
  end
end
