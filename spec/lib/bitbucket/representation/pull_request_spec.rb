# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Bitbucket::Representation::PullRequest, feature_category: :importers do
  describe '#iid' do
    it { expect(described_class.new('id' => 1).iid).to eq(1) }
  end

  describe '#author' do
    it { expect(described_class.new({ 'author' => { 'uuid' => '{123}' } }).author).to eq('{123}') }
    it { expect(described_class.new({ 'author' => { 'nickname' => 'Ben' } }).author).to be_nil }
    it { expect(described_class.new({}).author).to be_nil }
    it { expect(described_class.new({ 'author' => nil }).author).to be_nil }
  end

  describe '#author_nickname' do
    it { expect(described_class.new({ 'author' => { 'nickname' => 'Ben' } }).author_nickname).to eq('Ben') }
    it { expect(described_class.new({}).author_nickname).to be_nil }
    it { expect(described_class.new({ 'author' => nil }).author_nickname).to be_nil }
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

  describe '#created_at' do
    it { expect(described_class.new('created_on' => '2023-01-01').created_at).to eq('2023-01-01') }
  end

  describe '#updated_at' do
    it { expect(described_class.new('updated_on' => '2023-01-01').updated_at).to eq('2023-01-01') }
  end

  describe '#merge_commit_sha' do
    it { expect(described_class.new('merge_commit' => { 'hash' => 'SHA' }).merge_commit_sha).to eq('SHA') }
    it { expect(described_class.new({}).merge_commit_sha).to be_nil }
  end

  describe '#to_hash' do
    it do
      raw = {
        'id' => 11,
        'description' => 'description',
        'author' => { 'nickname' => 'user-1', 'uuid' => '{123}' },
        'state' => 'MERGED',
        'created_on' => 'created-at',
        'updated_on' => 'updated-at',
        'title' => 'title',
        'source' => {
          'branch' => { 'name' => 'source-branch-name' },
          'commit' => { 'hash' => 'source-commit-hash' },
          'repository' => { 'uuid' => 'uuid' }
        },
        'destination' => {
          'branch' => { 'name' => 'destination-branch-name' },
          'commit' => { 'hash' => 'destination-commit-hash' },
          'repository' => { 'uuid' => 'uuid' }
        },
        'merge_commit' => { 'hash' => 'merge-commit-hash' },
        'reviewers' => [
          {
            'uuid' => '{75364e21-112d-4381-9ec7-dcd615f0a690}',
            'nickname' => 'user-2'
          }
        ]
      }

      expected_hash = {
        author: '{123}',
        author_nickname: 'user-1',
        created_at: 'created-at',
        description: 'description',
        iid: 11,
        source_branch_name: 'source-branch-name',
        source_branch_sha: 'source-commit-hash',
        merge_commit_sha: 'merge-commit-hash',
        state: 'merged',
        closed_by: nil,
        target_branch_name: 'destination-branch-name',
        target_branch_sha: 'destination-commit-hash',
        title: 'title',
        updated_at: 'updated-at',
        source_and_target_project_different: false,
        reviewers: ['{75364e21-112d-4381-9ec7-dcd615f0a690}']
      }

      expect(described_class.new(raw).to_hash).to eq(expected_hash)
    end
  end
end
