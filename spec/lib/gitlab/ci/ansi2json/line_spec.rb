# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::Ci::Ansi2json::Line, feature_category: :continuous_integration do
  let(:offset) { 0 }
  let(:style) { Gitlab::Ci::Ansi2json::Style.new }

  subject(:line) { described_class.new(offset: offset, style: style) }

  describe '#<<' do
    it 'appends new data to the current segment' do
      expect { line << 'test 1' }.to change { line.current_segment.text }
      expect(line.current_segment.text).to eq('test 1')

      expect { line << ', test 2' }.to change { line.current_segment.text }
      expect(line.current_segment.text).to eq('test 1, test 2')
    end

    it 'resets line start flag' do
      expect { line << 'test 1' }.to change { line.at_line_start? }.from(true).to(false)
    end
  end

  describe '#clear!' do
    it 'clears at_line_start?' do
      line << 'test 1'

      expect { line.clear! }.to change { line.at_line_start? }.from(false).to(true)
    end

    it 'clears segments' do
      line << 'test 1'

      expect { line.clear! }.to change { line.empty? }.from(false).to(true)
    end
  end

  describe '#style' do
    context 'when style is passed to the initializer' do
      let(:style) { double }

      it 'returns the same style' do
        expect(line.style).to eq(style)
      end
    end

    context 'when style is not passed to the initializer' do
      it 'returns the default style' do
        expect(line.style.set?).to be_falsey
      end
    end
  end

  describe '#update_style' do
    let(:expected_style) do
      Gitlab::Ci::Ansi2json::Style.new(
        fg: 'term-fg-yellow',
        bg: 'term-bg-blue',
        mask: 1)
    end

    it 'sets the style' do
      line.update_style(%w[1 33 44])

      expect(line.style).to eq(expected_style)
    end
  end

  describe '#add_timestamp' do
    let(:timestamp) { '2024-05-14T11:19:19.899359Z' }

    it 'sets line timestamp' do
      line.add_timestamp(timestamp)
      expect(line.timestamp).to eq(timestamp)

      expect do
        line.add_timestamp('2024-05-14T11:19:20.899359Z')
      end.to change { line.timestamp }.to('2024-05-14T11:19:20.899359Z')
    end

    it 'does not reset line start flag' do
      expect { line.add_timestamp(timestamp) }.not_to change { line.at_line_start? }
    end
  end

  describe '#add_section' do
    it 'appends a new section to the list' do
      line.add_section('section_1')
      line.add_section('section_2')

      expect(line.sections).to eq(%w[section_1 section_2])
    end

    it 'resets line start flag' do
      expect { line.add_section('section_1') }.to change { line.at_line_start? }.from(true).to(false)
    end
  end

  describe '#set_section_options' do
    it 'sets the current section\'s options' do
      options = { collapsed: true }
      line.set_section_options(options)

      expect(line.to_h[:section_options]).to eq(options)
    end
  end

  describe '#set_as_section_header' do
    it 'change the section_header to true' do
      expect { line.set_as_section_header }
        .to change { line.section_header }
        .to be_truthy
    end
  end

  describe '#set_as_section_footer' do
    it 'change the section_footer to true' do
      expect { line.set_as_section_footer }
        .to change { line.section_footer }
        .to be_truthy
    end
  end

  describe '#set_section_duration' do
    using RSpec::Parameterized::TableSyntax

    where(:duration, :result) do
      nil                                         | '00:00'
      'string'                                    | '00:00'
      0.seconds                                   | '00:00'
      7.seconds                                   | '00:07'
      75                                          | '01:15'
      (1.minute + 15.seconds)                       | '01:15'
      (13.hours + 14.minutes + 15.seconds)          | '13:14:15'
      (1.day + 13.hours + 14.minutes + 15.seconds)  | '37:14:15'
      Float::MAX | '8765:00:00'
      (10**10000) | '8765:00:00'
    end

    with_them do
      it do
        line.set_section_duration(duration)

        expect(line.section_duration).to eq(result)
      end
    end
  end

  describe '#flush_current_segment!' do
    context 'when current segment is not empty' do
      before do
        line << 'some data'
      end

      it 'adds the segment to the list' do
        expect { line.flush_current_segment! }.to change { line.segments.count }.by(1)

        expect(line.segments.map { |s| s[:text] }).to eq(['some data'])
      end

      it 'updates the current segment pointer propagating the style' do
        previous_segment = line.current_segment

        line.flush_current_segment!

        expect(line.current_segment).not_to eq(previous_segment)
        expect(line.current_segment.style).to eq(previous_segment.style)
      end
    end

    context 'when current segment is empty' do
      it 'does not add any segments to the list' do
        expect { line.flush_current_segment! }.not_to change { line.segments.count }
      end

      it 'does not change the current segment' do
        expect { line.flush_current_segment! }.not_to change { line.current_segment }
      end
    end
  end

  describe '#to_h' do
    before do
      line << 'some data'
      line.update_style(['1'])
    end

    context 'when timestamps are present' do
      before do
        line.add_timestamp('2024-05-14T11:19:19.899359Z')
        line.add_timestamp('2024-05-14T11:19:20.899359Z')
      end

      it 'serializes the attributes set with the last timestamp' do
        result = {
          offset: 0,
          timestamp: '2024-05-14T11:19:20.899359Z',
          content: [{ text: 'some data', style: 'term-bold' }]
        }

        expect(line.to_h).to eq(result)
      end
    end

    context 'when sections are present' do
      before do
        line.add_section('section_1')
        line.add_section('section_2')
      end

      context 'when section header is set' do
        before do
          line.set_as_section_header
        end

        it 'serializes the attributes set' do
          result = {
            offset: 0,
            content: [{ text: 'some data', style: 'term-bold' }],
            section: 'section_2',
            section_header: true
          }

          expect(line.to_h).to eq(result)
        end
      end

      context 'when section duration is set' do
        before do
          line.set_section_duration(75)
        end

        it 'serializes the attributes set' do
          result = {
            offset: 0,
            content: [{ text: 'some data', style: 'term-bold' }],
            section: 'section_2',
            section_duration: '01:15'
          }

          expect(line.to_h).to eq(result)
        end
      end

      context 'when section footer is set' do
        before do
          line.set_as_section_footer
        end

        it 'serializes the attributes set' do
          result = {
            offset: 0,
            content: [{ text: 'some data', style: 'term-bold' }],
            section: 'section_2',
            section_footer: true
          }

          expect(line.to_h).to eq(result)
        end
      end
    end

    context 'when there are no sections' do
      it 'serializes the attributes set' do
        result = {
          offset: 0,
          content: [{ text: 'some data', style: 'term-bold' }]
        }

        expect(line.to_h).to eq(result)
      end
    end
  end
end
