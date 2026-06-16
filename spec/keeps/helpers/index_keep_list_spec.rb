# frozen_string_literal: true

require 'fast_spec_helper'
require './keeps/helpers/index_keep_list'

RSpec.describe Keeps::Helpers::IndexKeepList, feature_category: :database do
  let(:tmp_dir) { Pathname(Dir.mktmpdir) }
  let(:yaml_path) { tmp_dir.join('index_keep_list.yml') }

  subject(:keep_list) { described_class.new(yaml_path: yaml_path) }

  after do
    FileUtils.rm_rf(tmp_dir)
  end

  describe '#exempt?' do
    before do
      File.write(yaml_path, <<~YAML)
        ---
        "public.index_kept_for_self_managed":
          reason: "Used by self-managed-only feature."
          added_by: "@someone"
          added_on: "2026-05-22"
      YAML
    end

    it 'returns true for indexes listed in the YAML' do
      expect(keep_list.exempt?('public', 'index_kept_for_self_managed')).to be(true)
    end

    it 'returns false for indexes not listed' do
      expect(keep_list.exempt?('public', 'some_other_index')).to be(false)
    end
  end

  describe '#entries' do
    context 'when the file is an empty mapping' do
      before do
        File.write(yaml_path, "---\n{}\n")
      end

      it 'returns an empty hash' do
        expect(keep_list.entries).to eq({})
      end
    end

    context 'when an entry is missing a required key' do
      before do
        File.write(yaml_path, <<~YAML)
          ---
          "public.foo":
            reason: "no added_by here"
            added_on: "2026-05-22"
        YAML
      end

      it 'raises with a message naming the missing key' do
        expect { keep_list.entries }.to raise_error(described_class::Error, /added_by/)
      end
    end
  end
end
