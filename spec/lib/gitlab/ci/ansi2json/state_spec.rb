# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Ansi2json::State, feature_category: :continuous_integration do
  def build_state(state_class)
    state_class.new('', 1000).tap do |state|
      state.offset = 1
      state.new_line!(style: { fg: 'some-fg', bg: 'some-bg', mask: 1234 })
      state.set_last_line_offset
      state.open_section('hello', 111, {})
    end
  end

  let(:state) { build_state(described_class) }

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

    it 'ignores signed state' do
      signed_state = Gitlab::Ci::Ansi2json::SignedState.new('', 1000)
      signed_state.offset = 1
      signed_state.new_line!(style: { fg: 'some-fg', bg: 'some-bg', mask: 1234 })
      signed_state.set_last_line_offset
      signed_state.open_section('hello', 111, {})

      encoded = signed_state.encode
      expect(::Gitlab::AppLogger).to(
        receive(:warn).with(
          message: a_string_matching(/decode error/),
          invalid_state: encoded,
          error: an_instance_of(JSON::ParserError)
        )
      )
      new_state = described_class.new(encoded, 1000)
      expect(new_state.offset).to eq(0)
      expect(new_state.inherited_style).to eq({})
      expect(new_state.open_sections).to eq({})
    end

    it 'ignores invalid Base64 and logs a warning', :aggregate_failures do
      expect(::Gitlab::AppLogger).to(
        receive(:warn).with(
          message: a_string_matching(/decode error/),
          invalid_state: '.',
          error: an_instance_of(ArgumentError)
        )
      )

      new_state = described_class.new('.', 0)

      expect(new_state.offset).to eq(0)
      expect(new_state.inherited_style).to eq({})
      expect(new_state.open_sections).to eq({})
    end

    it 'ignores invalid JSON and logs a warning', :aggregate_failures do
      encoded = Base64.urlsafe_encode64('.')
      expect(::Gitlab::AppLogger).to(
        receive(:warn).with(
          message: a_string_matching(/decode error/),
          invalid_state: encoded,
          error: an_instance_of(JSON::ParserError)
        )
      )

      new_state = described_class.new(encoded, 0)
      expect(new_state.offset).to eq(0)
      expect(new_state.inherited_style).to eq({})
      expect(new_state.open_sections).to eq({})
    end
  end
end
