# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bitbucket::Representation::PullRequest do
  describe '#iid' do
    it { expect(described_class.new('id' => 1).iid).to eq(1) }
  end

  describe '#author' do
    it { expect(described_class.new({ 'author' => { 'nickname' => 'Ben' } }).author).to eq('Ben') }
    it { expect(described_class.new({}).author).to be_nil }
  end

  describe '#description' do
    it { expect(described_class.new({ 'description' => 'Text' }).description).to eq('Text') }
    it { expect(described_class.new({}).description).to be_nil }
  end

  describe '#state' do
    it { expect(described_class.new({ 'state' => 'MERGED' }).state).to eq('merged') }
    it { expect(described_class.new({ 'state' => 'DECLINED' }).state).to eq('closed') }
    it { expect(described_class.new({ 'state' => 'SUPERSEDED' }).state).to eq('closed') }
    it { expect(described_class.new({}).state).to eq('opened') }
  end

  describe '#title' do
    it { expect(described_class.new('title' => 'Issue').title).to eq('Issue') }
  end

  describe '#source_branch_name' do
    it { expect(described_class.new({ source: { branch: { name: 'feature' } } }.with_indifferent_access).source_branch_name).to eq('feature') }
    it { expect(described_class.new({ source: {} }.with_indifferent_access).source_branch_name).to be_nil }
  end

  describe '#source_branch_sha' do
    it { expect(described_class.new({ source: { commit: { hash: 'abcd123' } } }.with_indifferent_access).source_branch_sha).to eq('abcd123') }
    it { expect(described_class.new({ source: {} }.with_indifferent_access).source_branch_sha).to be_nil }
  end

  describe '#target_branch_name' do
    it { expect(described_class.new({ destination: { branch: { name: 'master' } } }.with_indifferent_access).target_branch_name).to eq('master') }
    it { expect(described_class.new({ destination: {} }.with_indifferent_access).target_branch_name).to be_nil }
  end

  describe '#target_branch_sha' do
    it { expect(described_class.new({ destination: { commit: { hash: 'abcd123' } } }.with_indifferent_access).target_branch_sha).to eq('abcd123') }
    it { expect(described_class.new({ destination: {} }.with_indifferent_access).target_branch_sha).to be_nil }
  end
end
