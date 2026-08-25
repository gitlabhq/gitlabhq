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

  describe '.transform_context' do
    subject(:context) { described_class.transform_context({}) }

    it 'marks the render as being for a Service Desk email', :aggregate_failures do
      expect(context).to include(for_email: true)
      expect(context).to include(for_service_desk_email: true)
    end
  end
end
