# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Attachments::BaseImporter, feature_category: :importers do
  subject(:importer) { importer_class.new(project, client) }

  let(:project) { instance_double(Project, id: 1) }
  let(:client) { instance_double(Gitlab::GithubImport::Client) }
  let(:importer_class) do
    Class.new(described_class) do
      private

      def collection_method
        'test'
      end
    end
  end

  describe '#each_object_to_import' do
    context 'with not implemented #collection interface' do
      it 'raises NotImplementedError' do
        expect { importer.each_object_to_import }
          .to raise_error(Gitlab::GithubImport::Exceptions::NotImplementedError, '#collection')
      end
    end
  end

  describe '#parallel?' do
    it 'returns true when running in parallel mode' do
      expect(importer).to be_parallel
    end

    it 'returns batch configuration with size and delay' do
      expect(importer.parallel_import_batch).to eq({ size: 100, delay: 1.minute })
    end
  end
end
