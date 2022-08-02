# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::RawDiffChange do
  let(:raw_change) {}
  let(:change) { described_class.new(raw_change) }

  context 'bad input' do
    let(:raw_change) { 'foo' }

    it 'does not set most of the attrs' do
      expect(change.blob_id).to eq('foo')
      expect(change.operation).to eq(:unknown)
      expect(change.old_path).to be_blank
      expect(change.new_path).to be_blank
      expect(change.blob_size).to eq(0)
    end
  end

  context 'adding a file' do
    let(:raw_change) { '93e123ac8a3e6a0b600953d7598af629dec7b735 59 A  bar/branch-test.txt' }

    it 'initialize the proper attrs' do
      expect(change.operation).to eq(:added)
      expect(change.old_path).to be_blank
      expect(change.new_path).to eq('bar/branch-test.txt')
      expect(change.blob_id).to be_present
      expect(change.blob_size).to be_present
    end
  end

  context 'renaming a file' do
    let(:raw_change) { "85bc2f9753afd5f4fc5d7c75f74f8d526f26b4f3 107 R060\tfiles/js/commit.js.coffee\tfiles/js/commit.coffee" }

    it 'initialize the proper attrs' do
      expect(change.operation).to eq(:renamed)
      expect(change.old_path).to eq('files/js/commit.js.coffee')
      expect(change.new_path).to eq('files/js/commit.coffee')
      expect(change.blob_id).to be_present
      expect(change.blob_size).to be_present
    end
  end

  context 'modifying a file' do
    let(:raw_change) { 'c60514b6d3d6bf4bec1030f70026e34dfbd69ad5 824 M  README.md' }

    it 'initialize the proper attrs' do
      expect(change.operation).to eq(:modified)
      expect(change.old_path).to eq('README.md')
      expect(change.new_path).to eq('README.md')
      expect(change.blob_id).to be_present
      expect(change.blob_size).to be_present
    end
  end

  context 'deleting a file' do
    let(:raw_change) { '60d7a906c2fd9e4509aeb1187b98d0ea7ce827c9 15364 D  files/.DS_Store' }

    it 'initialize the proper attrs' do
      expect(change.operation).to eq(:deleted)
      expect(change.old_path).to eq('files/.DS_Store')
      expect(change.new_path).to be_nil
      expect(change.blob_id).to be_present
      expect(change.blob_size).to be_present
    end
  end
end
