# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::FileDownloads::Validations, feature_category: :importers do
  let(:dummy_instance) { dummy_class.new }
  let(:dummy_class) do
    Class.new do
      include BulkImports::FileDownloads::Validations
    end
  end

  describe '#raise_error' do
    it { expect { dummy_instance.raise_error('text') }.to raise_exception(NotImplementedError) }
  end

  describe '#filepath' do
    it { expect { dummy_instance.filepath }.to raise_exception(NotImplementedError) }
  end

  describe '#response_headers' do
    it { expect { dummy_instance.response_headers }.to raise_exception(NotImplementedError) }
  end

  describe '#file_size_limit' do
    it { expect { dummy_instance.file_size_limit }.to raise_exception(NotImplementedError) }
  end
end
