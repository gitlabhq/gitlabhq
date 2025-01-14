# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::GithubImport::Representation::ExposeAttribute, feature_category: :importers do
  let(:klass) do
    Class.new do
      include Gitlab::GithubImport::Representation::ExposeAttribute

      expose_attribute :number

      attr_reader :attributes

      def initialize(attributes)
        @attributes = attributes
      end
    end
  end

  it 'defines a getter method that returns an attribute value' do
    expect(klass.new({ number: 42 }).number).to eq(42)
  end

  describe '#[]' do
    it 'returns exposed attributes value using array notation' do
      expect(klass.new({ number: 42 })[:number]).to eq(42)
    end

    context 'when attribute does not exist' do
      it 'returns nil' do
        expect(klass.new({})[:number]).to eq(nil)
      end
    end

    context 'when attribute is not exposed' do
      it 'returns nil' do
        expect(klass.new({ not_exposed_attribute: 42 })[:not_exposed_attribute]).to eq(nil)
      end
    end
  end
end
