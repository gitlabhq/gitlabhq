# frozen_string_literal: true

require 'fast_spec_helper'
require 'graphql'
require_relative '../../../../app/graphql/types/base_scalar'
require_relative '../../../../app/graphql/types/global_id_type'
require_relative '../../../support/helpers/global_id_deprecation_helpers'

RSpec.describe Gitlab::GlobalId::Deprecations do
  include GlobalIDDeprecationHelpers

  let(:deprecation_1) do
    described_class::NameDeprecation.new(old_name: 'Foo::Model', new_name: 'Bar', milestone: '9.0')
  end

  let(:deprecation_2) do
    described_class::NameDeprecation.new(old_name: 'Baz', new_name: 'Qux::Model', milestone: '10.0')
  end

  before do
    stub_global_id_deprecations(deprecation_1, deprecation_2)
  end

  describe '.deprecated?' do
    it 'returns a boolean to signal if model name has a deprecation', :aggregate_failures do
      expect(described_class.deprecated?('Foo::Model')).to eq(true)
      expect(described_class.deprecated?('Qux::Model')).to eq(false)
    end
  end

  describe '.deprecation_for' do
    it 'returns the deprecation for the model if it exists', :aggregate_failures do
      expect(described_class.deprecation_for('Foo::Model')).to eq(deprecation_1)
      expect(described_class.deprecation_for('Qux::Model')).to be_nil
    end
  end

  describe '.deprecation_by' do
    it 'returns the deprecation by the model if it exists', :aggregate_failures do
      expect(described_class.deprecation_by('Foo::Model')).to be_nil
      expect(described_class.deprecation_by('Qux::Model')).to eq(deprecation_2)
    end
  end

  describe '.apply_to_graphql_name' do
    it 'returns the corresponding graphql_name of the GID for the new model', :aggregate_failures do
      expect(described_class.apply_to_graphql_name('FooModelID')).to eq('BarID')
      expect(described_class.apply_to_graphql_name('BazID')).to eq('QuxModelID')
    end

    it 'returns the same value if there is no deprecation' do
      expect(described_class.apply_to_graphql_name('ProjectID')).to eq('ProjectID')
    end
  end
end
