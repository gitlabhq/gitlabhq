# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Ansi2json::Line do
  let(:offset) { 0 }
  let(:style) { Gitlab::Ci::Ansi2json::Style.new }

  subject { described_class.new(offset: offset, style: style) }

  describe '#<<' do
    it 'appends new data to the current segment' do
      expect { subject << 'test 1' }.to change { subject.current_segment.text }
      expect(subject.current_segment.text).to eq('test 1')

      expect { subject << ', test 2' }.to change { subject.current_segment.text }
      expect(subject.current_segment.text).to eq('test 1, test 2')
    end
  end

  describe '#style' do
    context 'when style is passed to the initializer' do
      let(:style) { double }

      it 'returns the same style' do
        expect(subject.style).to eq(style)
      end
    end

    context 'when style is not passed to the initializer' do
      it 'returns the default style' do
        expect(subject.style.set?).to be_falsey
      end
    end
  end

  describe '#update_style' do
    let(:expected_style) do
      Gitlab::Ci::Ansi2json::Style.new(
        fg: 'term-fg-l-yellow',
        bg: 'term-bg-blue',
        mask: 1)
    end

    it 'sets the style' do
      subject.update_style(%w[1 33 44])

      expect(subject.style).to eq(expected_style)
    end
  end

  describe '#add_section' do
    it 'appends a new section to the list' do
      subject.add_section('section_1')
      subject.add_section('section_2')

      expect(subject.sections).to eq(%w[section_1 section_2])
    end
  end

  describe '#set_section_options' do
    it 'sets the current section\'s options' do
      options = { collapsed: true }
      subject.set_section_options(options)

      expect(subject.to_h[:section_options]).to eq(options)
    end
  end

  describe '#set_as_section_header' do
    it 'change the section_header to true' do
      expect { subject.set_as_section_header }
        .to change { subject.section_header }
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
      1.minute + 15.seconds                       | '01:15'
      13.hours + 14.minutes + 15.seconds          | '13:14:15'
      1.day + 13.hours + 14.minutes + 15.seconds  | '37:14:15'
    end

    with_them do
      it do
        subject.set_section_duration(duration)

        expect(subject.section_duration).to eq(result)
      end
    end
  end

  describe '#flush_current_segment!' do
    context 'when current segment is not empty' do
      before do
        subject << 'some data'
      end

      it 'adds the segment to the list' do
        expect { subject.flush_current_segment! }.to change { subject.segments.count }.by(1)

        expect(subject.segments.map { |s| s[:text] }).to eq(['some data'])
      end

      it 'updates the current segment pointer propagating the style' do
        previous_segment = subject.current_segment

        subject.flush_current_segment!

        expect(subject.current_segment).not_to eq(previous_segment)
        expect(subject.current_segment.style).to eq(previous_segment.style)
      end
    end

    context 'when current segment is empty' do
      it 'does not add any segments to the list' do
        expect { subject.flush_current_segment! }.not_to change { subject.segments.count }
      end

      it 'does not change the current segment' do
        expect { subject.flush_current_segment! }.not_to change { subject.current_segment }
      end
    end
  end

  describe '#to_h' do
    before do
      subject << 'some data'
      subject.update_style(['1'])
    end

    context 'when sections are present' do
      before do
        subject.add_section('section_1')
        subject.add_section('section_2')
      end

      context 'when section header is set' do
        before do
          subject.set_as_section_header
        end

        it 'serializes the attributes set' do
          result = {
            offset: 0,
            content: [{ text: 'some data', style: 'term-bold' }],
            section: 'section_2',
            section_header: true
          }

          expect(subject.to_h).to eq(result)
        end
      end

      context 'when section duration is set' do
        before do
          subject.set_section_duration(75)
        end

        it 'serializes the attributes set' do
          result = {
            offset: 0,
            content: [{ text: 'some data', style: 'term-bold' }],
            section: 'section_2',
            section_duration: '01:15'
          }

          expect(subject.to_h).to eq(result)
        end
      end
    end

    context 'when there are no sections' do
      it 'serializes the attributes set' do
        result = {
          offset: 0,
          content: [{ text: 'some data', style: 'term-bold' }]
        }

        expect(subject.to_h).to eq(result)
      end
    end
  end
end
