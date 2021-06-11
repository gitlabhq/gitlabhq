# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_example'

RSpec.describe Gitlab::ImportExport::Json::LegacyReader::Hash do
  it_behaves_like 'import/export json legacy reader' do
    let(:path) { 'spec/fixtures/lib/gitlab/import_export/light/project.json' }

    # the hash is modified by the `LegacyReader`
    # we need to deep-dup it
    let(:json_data) { Gitlab::Json.parse(File.read(path)) }
    let(:data) { Gitlab::Json.parse(File.read(path)) }
  end

  describe '#exist?' do
    let(:legacy_reader) do
      described_class.new(tree_hash, relation_names: [])
    end

    subject { legacy_reader.exist? }

    context 'tree_hash is nil' do
      let(:tree_hash) { nil }

      it { is_expected.to be_falsey }
    end

    context 'tree_hash presents' do
      let(:tree_hash) { { "issues": [] } }

      it { is_expected.to be_truthy }
    end
  end
end
