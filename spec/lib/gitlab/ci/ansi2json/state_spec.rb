# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Ansi2json::State, feature_category: :continuous_integration do
  def build_state
    described_class.new('', 1000).tap do |state|
      state.offset = 1
      state.new_line!(style: { fg: 'some-fg', bg: 'some-bg', mask: 1234 })
      state.set_last_line_offset
      state.open_section('hello', 111, {})
    end
  end

  let(:state) { build_state }

  describe '#initialize' do
    it 'restores valid prior state', :aggregate_failures do
      new_state = described_class.new(state.encode, 1000)

      expect(new_state.offset).to eq(1)
      expect(new_state.inherited_style).to eq({
        bg: 'some-bg',
        fg: 'some-fg',
        mask: 1234
      })
      expect(new_state.open_sections).to eq({ 'hello' => 111 })
    end

    it 'ignores unsigned prior state', :aggregate_failures do
      unsigned, _ = build_state.encode.split('--')

      expect(::Gitlab::AppLogger).to(
        receive(:warn).with(
          message: a_string_matching(/signature missing or invalid/),
          invalid_state: unsigned
        )
      )

      new_state = described_class.new(unsigned, 0)

      expect(new_state.offset).to eq(0)
      expect(new_state.inherited_style).to eq({})
      expect(new_state.open_sections).to eq({})
    end

    it 'ignores bad input', :aggregate_failures do
      expect(::Gitlab::AppLogger).to(
        receive(:warn).with(
          message: a_string_matching(/signature missing or invalid/),
          invalid_state: 'abcd'
        )
      )

      new_state = described_class.new('abcd', 0)

      expect(new_state.offset).to eq(0)
      expect(new_state.inherited_style).to eq({})
      expect(new_state.open_sections).to eq({})
    end
  end

  describe '#encode' do
    it 'deterministically signs the state' do
      expect(state.encode).to eq state.encode
    end
  end
end
