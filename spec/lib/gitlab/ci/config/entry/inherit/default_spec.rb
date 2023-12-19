# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Config::Entry::Inherit::Default do
  using RSpec::Parameterized::TableSyntax

  subject { described_class.new(config) }

  context 'validations' do
    where(:config, :valid) do
      true        | true
      false       | true
      %w[image]   | true
      %w[unknown] | false
      %i[image]   | false
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
      true              | true
      false             | false
      %w[image]         | true
      %w[before_script] | false
      '123'             | false
    end

    with_them do
      it do
        expect(subject.inherit?('image')).to eq(inherit)
      end
    end
  end
end
