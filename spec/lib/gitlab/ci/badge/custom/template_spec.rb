# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Badge::Custom::Template, feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }
  let(:options) { {} }
  let(:badge) { Gitlab::Ci::Badge::Custom::CustomBadge.new(project, opts: options) }
  let(:template) { described_class.new(badge) }

  it_behaves_like 'a badge template', 'custom'

  where(:input_color, :expected_color) do
    nil                    | ref(:default_color)
    ''                     | ref(:default_color)
    'ee4035'               | '#ee4035'
    ' 4B0EC3 '             | '#4b0ec3'
    '#4167baa'             | ref(:default_color)
    '#c0c0c0'              | '#c0c0c0'
    '%23fff0'              | ref(:default_color)
    'EEE '                 | '#eee'
    'fff'                  | '#fff'
    'ffff'                 | 'ffff'
    '#000'                 | '#000'
    'f03'                  | ref(:default_color)
    'blue2'                | ref(:default_color)
    'blanchedAlmond '      | 'blanchedalmond'
    'lightgoldenrodyellow' | 'lightgoldenrodyellow'
  end

  with_them do
    let(:options) { { key_color: input_color, value_color: input_color } }

    describe '#key_color' do
      let(:default_color) { described_class::KEY_COLOR_DEFAULT }

      it 'returns expected color' do
        expect(template.key_color).to eq(expected_color)
      end
    end

    describe '#value_color' do
      let(:default_color) { described_class::VALUE_COLOR_DEFAULT }

      it 'returns expected color' do
        expect(template.value_color).to eq(expected_color)
      end
    end
  end

  describe '#key_text' do
    it 'defaults to custom' do
      expect(template.key_text).to eq('custom')
    end

    context 'with custom key text' do
      let(:options) { { key_text: 'Hello' } }

      it 'returns custom key' do
        expect(template.key_text).to eq('Hello')
      end
    end
  end

  describe '#value_text' do
    it 'defaults to none' do
      expect(template.value_text).to eq('none')
    end

    context 'with custom value text' do
      let(:options) { { value_text: 'world' } }

      it 'returns custom value' do
        expect(template.value_text).to eq('world')
      end
    end
  end

  describe '#value_width' do
    let(:default_value_width) { described_class::VALUE_WIDTH_DEFAULT }

    where(:input_value_width, :expected_value_width) do
      nil      | ref(:default_value_width)
      1        | 1
      100      | 100
      200      | 200
      300      | ref(:default_value_width)
      0        | ref(:default_value_width)
      -1       | ref(:default_value_width)
      ''       | ref(:default_value_width)
      'string' | ref(:default_value_width)
    end

    with_them do
      let(:options) { { value_width: input_value_width } }

      it 'returns valid value width' do
        expect(template.value_width).to eq(expected_value_width)
      end
    end
  end
end
