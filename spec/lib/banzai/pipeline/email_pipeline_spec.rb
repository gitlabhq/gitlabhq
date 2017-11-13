require 'rails_helper'

describe Banzai::Pipeline::EmailPipeline do
  describe '.filters' do
    it 'returns the expected type' do
      expect(described_class.filters).to be_kind_of(Banzai::FilterArray)
    end

    it 'excludes ImageLazyLoadFilter' do
      expect(described_class.filters).not_to be_empty
      expect(described_class.filters).not_to include(Banzai::Filter::ImageLazyLoadFilter)
    end
  end
end
