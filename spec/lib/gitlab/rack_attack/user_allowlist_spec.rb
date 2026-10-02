# frozen_string_literal: true

require 'fast_spec_helper'
require 'labkit/context'
require 'gitlab/safe_request_store'

RSpec.describe Gitlab::RackAttack::UserAllowlist, feature_category: :rate_limiting do
  using RSpec::Parameterized::TableSyntax

  subject { described_class.new(input) }

  where(:input, :elements) do
    nil | []
    '' |  []
    '123' | [123]
    '123,456' | [123, 456]
    '123,foobar, 456,' | [123, 456]
  end

  with_them do
    it 'has the expected elements' do
      expect(subject).to contain_exactly(*elements)
    end

    it 'implements empty?' do
      expect(subject.empty?).to eq(elements.empty?)
    end

    it 'implements include?' do
      unless elements.empty?
        expect(subject).to include(elements.first)
      end
    end
  end
end
