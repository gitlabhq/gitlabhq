# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Config::Entry::Inherit::Variables do
  using RSpec::Parameterized::TableSyntax

  subject { described_class.new(config) }

  context 'validations' do
    where(:config, :valid) do
      true        | true
      false       | true
      %w[A]       | true
      %w[A B]     | true
      %i[image]   | true
      [true]      | false
      "string"    | false
    end

    with_them do
      it do
        expect(subject.valid?).to eq(valid)
      end
    end
  end

  describe '#inherit?' do
    where(:config, :inherit) do
      true  | true
      false | false
      %w[A] | true
      %w[B] | false
    end

    with_them do
      it do
        expect(subject.inherit?('A')).to eq(inherit)
      end
    end
  end
end
