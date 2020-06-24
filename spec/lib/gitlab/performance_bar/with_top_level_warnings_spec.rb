# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::PerformanceBar::WithTopLevelWarnings do
  using RSpec::Parameterized::TableSyntax

  subject { Module.new }

  before do
    subject.singleton_class.prepend(described_class)
  end

  describe '#has_warnings?' do
    where(:has_warnings, :results) do
      false | { data: {} }
      false | { data: { gitaly: { warnings: [] } } }
      true  | { data: { gitaly: { warnings: [1] } } }
      true  | { data: { gitaly: { warnings: [] }, redis: { warnings: [1] } } }
    end

    with_them do
      it do
        expect(subject.has_warnings?(results)).to eq(has_warnings)
      end
    end
  end
end
