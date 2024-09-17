# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::ServiceDeskEmailPipeline, feature_category: :service_desk do
  it_behaves_like 'sanitize pipeline'

  describe '.filters' do
    it 'returns the expected type' do
      expect(described_class.filters).to be_kind_of(Banzai::FilterArray)
    end

    it 'excludes ServiceDeskUploadLinkFilter' do
      expect(described_class.filters).not_to be_empty
      expect(described_class.filters).to include(Banzai::Filter::ServiceDeskUploadLinkFilter)
    end
  end
end
