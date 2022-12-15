# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

require_relative '../../../support/shared_contexts/lib/sbom/package_url_shared_contexts'

RSpec.describe Sbom::PackageUrl::ArgumentValidator, feature_category: :dependency_management do
  let(:mock_package_url) { Struct.new(:type, :namespace, :name, :version, :qualifiers, keyword_init: true) }
  let(:package) do
    mock_package_url.new(
      type: type,
      namespace: namespace,
      name: name,
      version: version,
      qualifiers: qualifiers
    )
  end

  subject(:validate) { described_class.new(package).validate! }

  context 'with valid arguments' do
    include_context 'with valid purl examples'

    with_them do
      it 'does not raise error' do
        expect { validate }.not_to raise_error
      end
    end
  end

  context 'with invalid arguments' do
    include_context 'with invalid purl examples'

    with_them do
      it 'raises an ArgumentError' do
        expect { validate }.to raise_error(ArgumentError)
      end
    end
  end

  context 'with multiple errors' do
    let(:type) { nil }
    let(:name) { nil }
    let(:package) { mock_package_url.new(type: type, name: name) }

    it 'reports all errors' do
      expect { validate }.to raise_error(ArgumentError, 'Type is required, Name is required')
    end
  end
end
