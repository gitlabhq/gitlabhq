# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_example'

RSpec.describe Gitlab::ImportExport::Json::LegacyReader::File do
  it_behaves_like 'import/export json legacy reader' do
    let(:valid_path) { 'spec/fixtures/lib/gitlab/import_export/light/project.json' }
    let(:data) { valid_path }
    let(:json_data) { Gitlab::Json.parse(File.read(valid_path)) }
  end

  describe '#exist?' do
    let(:legacy_reader) do
      described_class.new(path, relation_names: [])
    end

    subject { legacy_reader.exist? }

    context 'given valid path' do
      let(:path) { 'spec/fixtures/lib/gitlab/import_export/light/project.json' }

      it { is_expected.to be true }
    end

    context 'given invalid path' do
      let(:path) { 'spec/non-existing-folder/do-not-create-this-file.json' }

      it { is_expected.to be false }
    end
  end
end
