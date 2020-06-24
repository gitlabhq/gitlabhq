# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bitbucket::Representation::Repo do
  describe '#has_wiki?' do
    it { expect(described_class.new({ 'has_wiki' => false }).has_wiki?).to be_falsey }
    it { expect(described_class.new({ 'has_wiki' => true }).has_wiki?).to be_truthy }
  end

  describe '#name' do
    it { expect(described_class.new({ 'name' => 'test' }).name).to eq('test') }
  end

  describe '#valid?' do
    it { expect(described_class.new({ 'scm' => 'hg' }).valid?).to be_falsey }
    it { expect(described_class.new({ 'scm' => 'git' }).valid?).to be_truthy }
  end

  describe '#full_name' do
    it { expect(described_class.new({ 'full_name' => 'test_full' }).full_name).to eq('test_full') }
  end

  describe '#description' do
    it { expect(described_class.new({ 'description' => 'desc' }).description).to eq('desc') }
  end

  describe '#issues_enabled?' do
    it { expect(described_class.new({ 'has_issues' => false }).issues_enabled?).to be_falsey }
    it { expect(described_class.new({ 'has_issues' => true }).issues_enabled?).to be_truthy }
  end

  describe '#owner_and_slug' do
    it { expect(described_class.new({ 'full_name' => 'ben/test' }).owner_and_slug).to eq(%w(ben test)) }
  end

  describe '#owner' do
    it { expect(described_class.new({ 'full_name' => 'ben/test' }).owner).to eq('ben') }
  end

  describe '#slug' do
    it { expect(described_class.new({ 'full_name' => 'ben/test' }).slug).to eq('test') }
  end

  describe '#clone_url' do
    it 'builds url' do
      data = { 'links' => { 'clone' => [{ 'name' => 'https', 'href' => 'https://bibucket.org/test/test.git' }] } }
      expect(described_class.new(data).clone_url('abc')).to eq('https://x-token-auth:abc@bibucket.org/test/test.git')
    end
  end
end
