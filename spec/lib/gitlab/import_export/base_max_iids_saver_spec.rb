# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::BaseMaxIidsSaver, feature_category: :importers do
  # Use an anonymous subclass to test the base class behavior
  let(:test_class) do
    Class.new(described_class) do
      def self.name
        'TestMaxIidsSaver'
      end

      def self.resource_queries
        {
          test_resource: ->(exportable) { exportable.id * 10 }
        }
      end
    end
  end

  let(:exportable) { create(:project) }
  let(:export_path) { Dir.mktmpdir('base_max_iids_saver_spec') }
  let(:shared) { instance_double(Gitlab::ImportExport::Shared, export_path: export_path, error: nil) }

  subject(:saver) { test_class.new(exportable: exportable, shared: shared) }

  after do
    FileUtils.rm_rf(export_path)
  end

  describe '#save' do
    it 'returns true on success' do
      expect(saver.save).to be true
    end

    it 'writes max_iids.json to the export path' do
      expect(saver.save).to be true

      expect(File).to exist(File.join(export_path, 'max_iids.json'))
    end

    it 'writes the computed max IIDs from resource_queries' do
      expect(saver.save).to be true

      content = Gitlab::Json.safe_parse(File.read(File.join(export_path, 'max_iids.json')))

      expect(content).to eq('test_resource' => exportable.id * 10)
    end

    it 'omits resources where the query returns nil' do
      allow(test_class).to receive(:resource_queries).and_return(
        test_resource: ->(_) { nil },
        another_resource: ->(_) { 42 }
      )

      expect(saver.save).to be true

      content = Gitlab::Json.safe_parse(File.read(File.join(export_path, 'max_iids.json')))

      expect(content).to eq('another_resource' => 42)
      expect(content).not_to have_key('test_resource')
    end

    context 'when an error occurs' do
      before do
        allow_next_instance_of(Gitlab::ImportExport::Json::NdjsonWriter) do |writer|
          allow(writer).to receive(:write_attributes).and_raise(Errno::EACCES, 'Permission denied')
        end
      end

      it 'returns false' do
        expect(saver.save).to be false
      end

      it 'reports the error to shared' do
        expect(shared).to receive(:error).with(instance_of(Errno::EACCES))

        expect(saver.save).to be false
      end
    end
  end

  describe '.resource_queries' do
    it 'raises NotImplementedError on the base class' do
      expect { described_class.resource_queries }.to raise_error(NotImplementedError)
    end
  end
end
