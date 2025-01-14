# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::SingleEndpointNotesImporting, feature_category: :importers do
  let(:importer_class) do
    Class.new do
      def self.name
        'MyImporter'
      end

      include(Gitlab::GithubImport::SingleEndpointNotesImporting)
    end
  end

  let(:importer_instance) { importer_class.new }

  describe '#parent_collection' do
    it { expect { importer_instance.parent_collection }.to raise_error(NotImplementedError) }
  end

  describe '#parent_imported_cache_key' do
    it { expect { importer_instance.parent_imported_cache_key }.to raise_error(NotImplementedError) }
  end

  describe '#page_counter_id' do
    it { expect { importer_instance.page_counter_id(build(:merge_request)) }.to raise_error(NotImplementedError) }
  end
end
