# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Ansi2json::Style do
  describe '#set?' do
    subject { described_class.new(params).set? }

    context 'when fg color is set' do
      let(:params) { { fg: 'term-fg-black' } }

      it { is_expected.to be_truthy }
    end

    context 'when bg color is set' do
      let(:params) { { bg: 'term-bg-black' } }

      it { is_expected.to be_truthy }
    end

    context 'when mask is set' do
      let(:params) { { mask: 0x01 } }

      it { is_expected.to be_truthy }
    end

    context 'nothing is set' do
      let(:params) { {} }

      it { is_expected.to be_falsey }
    end
  end

  describe '#reset!' do
    let(:style) { described_class.new(fg: 'term-fg-black', bg: 'term-bg-yellow', mask: 0x01) }

    it 'set the style params to default' do
      style.reset!

      expect(style.fg).to be_nil
      expect(style.bg).to be_nil
      expect(style.mask).to be_zero
    end
  end

  describe 'update formats to mimic terminals' do
    subject { described_class.new(params) }

    context 'when fg color present' do
      let(:params) { { fg: 'term-fg-black', mask: mask } }

      context 'when mask is set to bold' do
        let(:mask) { 0x01 }

        it 'changes the fg color to a lighter version' do
          expect(subject.fg).to eq('term-fg-l-black')
        end
      end

      context 'when mask set to another format' do
        let(:mask) { 0x02 }

        it 'does not change the fg color' do
          expect(subject.fg).to eq('term-fg-black')
        end
      end

      context 'when mask is not set' do
        let(:mask) { 0 }

        it 'does not change the fg color' do
          expect(subject.fg).to eq('term-fg-black')
        end
      end
    end
  end

  describe '#update' do
    where(:initial_state, :ansi_commands, :result, :description) do
      [
        # add format
        [[], %w[0], '', 'does not set any style'],
        [[], %w[1], 'term-bold', 'enables format bold'],
        [[], %w[3], 'term-italic', 'enables format italic'],
        [[], %w[4], 'term-underline', 'enables format underline'],
        [[], %w[8], 'term-conceal', 'enables format conceal'],
        [[], %w[9], 'term-cross', 'enables format cross'],
        # remove format
        [%w[1], %w[21], '', 'disables format bold'],
        [%w[1 3], %w[21], 'term-italic', 'disables format bold and leaves italic'],
        [%w[1], %w[22], '', 'disables format bold using command 22'],
        [%w[1 3], %w[22], 'term-italic', 'disables format bold and leaves italic using command 22'],
        [%w[3], %w[23], '', 'disables format italic'],
        [%w[1 3], %w[23], 'term-bold', 'disables format italic and leaves bold'],
        [%w[4], %w[24], '', 'disables format underline'],
        [%w[1 4], %w[24], 'term-bold', 'disables format underline and leaves bold'],
        [%w[8], %w[28], '', 'disables format conceal'],
        [%w[1 8], %w[28], 'term-bold', 'disables format conceal and leaves bold'],
        [%w[9], %w[29], '', 'disables format cross'],
        [%w[1 9], %w[29], 'term-bold', 'disables format cross and leaves bold'],
        # set fg color
        [[], %w[30], 'term-fg-black', 'sets fg color black'],
        [[], %w[31], 'term-fg-red', 'sets fg color red'],
        [[], %w[32], 'term-fg-green', 'sets fg color green'],
        [[], %w[33], 'term-fg-yellow', 'sets fg color yellow'],
        [[], %w[34], 'term-fg-blue', 'sets fg color blue'],
        [[], %w[35], 'term-fg-magenta', 'sets fg color magenta'],
        [[], %w[36], 'term-fg-cyan', 'sets fg color cyan'],
        [[], %w[37], 'term-fg-white', 'sets fg color white'],
        # sets xterm fg color
        [[], %w[38 5 1], 'xterm-fg-1', 'sets xterm fg color 1'],
        [[], %w[38 5 2], 'xterm-fg-2', 'sets xterm fg color 2'],
        [[], %w[38 1], 'term-bold', 'ignores 38 command if not followed by 5 and sets format bold'],
        # set bg color
        [[], %w[40], 'term-bg-black', 'sets bg color black'],
        [[], %w[41], 'term-bg-red', 'sets bg color red'],
        [[], %w[42], 'term-bg-green', 'sets bg color green'],
        [[], %w[43], 'term-bg-yellow', 'sets bg color yellow'],
        [[], %w[44], 'term-bg-blue', 'sets bg color blue'],
        [[], %w[45], 'term-bg-magenta', 'sets bg color magenta'],
        [[], %w[46], 'term-bg-cyan', 'sets bg color cyan'],
        [[], %w[47], 'term-bg-white', 'sets bg color white'],
        # set xterm bg color
        [[], %w[48 5 1], 'xterm-bg-1', 'sets xterm bg color 1'],
        [[], %w[48 5 2], 'xterm-bg-2', 'sets xterm bg color 2'],
        [[], %w[48 1], 'term-bold', 'ignores 48 command if not followed by 5 and sets format bold'],
        # set light fg color
        [[], %w[90], 'term-fg-l-black', 'sets fg color light black'],
        [[], %w[91], 'term-fg-l-red', 'sets fg color light red'],
        [[], %w[92], 'term-fg-l-green', 'sets fg color light green'],
        [[], %w[93], 'term-fg-l-yellow', 'sets fg color light yellow'],
        [[], %w[94], 'term-fg-l-blue', 'sets fg color light blue'],
        [[], %w[95], 'term-fg-l-magenta', 'sets fg color light magenta'],
        [[], %w[96], 'term-fg-l-cyan', 'sets fg color light cyan'],
        [[], %w[97], 'term-fg-l-white', 'sets fg color light white'],
        # set light bg color
        [[], %w[100], 'term-bg-l-black', 'sets bg color light black'],
        [[], %w[101], 'term-bg-l-red', 'sets bg color light red'],
        [[], %w[102], 'term-bg-l-green', 'sets bg color light green'],
        [[], %w[103], 'term-bg-l-yellow', 'sets bg color light yellow'],
        [[], %w[104], 'term-bg-l-blue', 'sets bg color light blue'],
        [[], %w[105], 'term-bg-l-magenta', 'sets bg color light magenta'],
        [[], %w[106], 'term-bg-l-cyan', 'sets bg color light cyan'],
        [[], %w[107], 'term-bg-l-white', 'sets bg color light white'],
        # reset
        [%w[1], %w[], '', 'resets style from format bold'],
        [%w[1], %w[0], '', 'resets style from format bold'],
        [%w[1 3], %w[0], '', 'resets style from format bold and italic'],
        [%w[1 3 term-fg-l-red term-bg-yellow], %w[0], '', 'resets all formats and colors'],
        # default foreground
        [%w[31 42], %w[39], 'term-bg-green', 'set foreground from red to default leaving background unchanged'],
        # default background
        [%w[31 42], %w[49], 'term-fg-red', 'set background from green to default leaving foreground unchanged'],
        # misc
        [[], %w[1 30 42 3], 'term-fg-l-black term-bg-green term-bold term-italic', 'adds fg color, bg color and formats from no style'],
        [%w[3 31], %w[23 1 43], 'term-fg-l-red term-bg-yellow term-bold', 'replaces format italic with bold and adds a yellow background']
      ]
    end

    with_them do
      it 'change the style' do
        style = described_class.new
        style.update(initial_state)

        style.update(ansi_commands)

        expect(style.to_s).to eq(result)
      end
    end
  end
end
