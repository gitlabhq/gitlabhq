# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GithubImport::Representation::ExposeAttribute do
  it 'defines a getter method that returns an attribute value' do
    klass = Class.new do
      include Gitlab::GithubImport::Representation::ExposeAttribute

      expose_attribute :number

      attr_reader :attributes

      def initialize
        @attributes = { number: 42 }
      end
    end

    expect(klass.new.number).to eq(42)
  end
end
