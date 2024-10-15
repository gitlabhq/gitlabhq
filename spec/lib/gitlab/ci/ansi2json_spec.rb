# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Ansi2json, feature_category: :continuous_integration do
  subject { described_class }

  describe 'lines' do
    it 'prints non-ansi as-is' do
      expect(convert_json('Hello')).to eq([{ offset: 0, content: [{ text: 'Hello' }] }])
    end

    context 'new lines' do
      it 'adds new line when encountering \n' do
        expect(convert_json("Hello\nworld")).to eq(
          [
            { offset: 0, content: [{ text: 'Hello' }] },
            { offset: 6, content: [{ text: 'world' }] }
          ])
      end

      it 'adds new line when encountering \r\n' do
        expect(convert_json("Hello\r\nworld")).to eq(
          [
            { offset: 0, content: [{ text: 'Hello' }] },
            { offset: 7, content: [{ text: 'world' }] }
          ])
      end

      it 'adds new line when encountering \r\r\n' do
        expect(convert_json("Hello\r\r\nworld")).to eq(
          [
            { offset: 0, content: [{ text: 'Hello' }] },
            { offset: 8, content: [{ text: 'world' }] }
          ])
      end

      it 'ignores empty newlines' do
        expect(convert_json("Hello\n\nworld")).to eq(
          [
            { offset: 0, content: [{ text: 'Hello' }] },
            { offset: 7, content: [{ text: 'world' }] }
          ])
        expect(convert_json("Hello\r\n\r\nworld")).to eq(
          [
            { offset: 0, content: [{ text: 'Hello' }] },
            { offset: 9, content: [{ text: 'world' }] }
          ])
      end

      it 'replaces the current line when encountering \r' do
        expect(convert_json("Hello\rworld")).to eq([{ offset: 0, content: [{ text: 'world' }] }])
      end
    end

    context 'with ANSI sequences' do
      it 'recognizes color changing ANSI sequences' do
        expect(convert_json("\e[31mHello\e[0m")).to eq(
          [
            { offset: 0, content: [{ text: 'Hello', style: 'term-fg-red' }] }
          ])
      end

      it 'recognizes color changing ANSI sequences across multiple lines' do
        expect(convert_json("\e[31mHello\nWorld\e[0m")).to eq(
          [
            { offset: 0, content: [{ text: 'Hello', style: 'term-fg-red' }] },
            { offset: 11, content: [{ text: 'World', style: 'term-fg-red' }] }
          ])
      end

      it 'recognizes background and foreground colors' do
        expect(convert_json("\e[31;44mHello")).to eq(
          [
            { offset: 0, content: [{ text: 'Hello', style: 'term-fg-red term-bg-blue' }] }
          ])
      end

      it 'recognizes style changes within the same line' do
        expect(convert_json("\e[31;44mHello\e[0m world")).to eq(
          [
            { offset: 0, content: [
              { text: 'Hello', style: 'term-fg-red term-bg-blue' },
              { text: ' world' }
            ] }
          ])
      end
    end

    context 'with section markers' do
      let(:section_name) { 'prepare-script' }
      let(:section_duration) { 63.seconds }
      let(:section_start_time) { Time.new(2019, 9, 17).utc }
      let(:section_end_time) { section_start_time + section_duration }
      let(:section_start) { "section_start:#{section_start_time.to_i}:#{section_name}\r\033[0K" }
      let(:section_end) { "section_end:#{section_end_time.to_i}:#{section_name}\r\033[0K" }

      it 'marks the first line of the section as header' do
        expect(convert_json("Hello#{section_start}world!")).to eq(
          [
            {
              offset: 0,
              content: [{ text: 'Hello' }]
            },
            {
              offset: 5,
              content: [{ text: 'world!' }],
              section: section_name,
              section_header: true
            }
          ])
      end

      it 'does not mark the other lines of the section as header' do
        expect(convert_json("outside section#{section_start}Hello\nworld!")).to eq(
          [
            {
              offset: 0,
              content: [{ text: 'outside section' }]
            },
            {
              offset: 15,
              content: [{ text: 'Hello' }],
              section: section_name,
              section_header: true
            },
            {
              offset: 65,
              content: [{ text: 'world!' }],
              section: section_name
            }
          ])
      end

      it 'marks the last line of the section as footer' do
        expect(convert_json("#{section_start}Good\nmorning\nworld!#{section_end}")).to eq(
          [
            {
              offset: 0,
              content: [{ text: 'Good' }],
              section: section_name,
              section_header: true
            },
            {
              offset: 49,
              content: [{ text: 'morning' }],
              section: section_name
            },
            {
              offset: 57,
              content: [{ text: 'world!' }],
              section: section_name
            },
            {
              offset: 63,
              content: [],
              section_duration: '01:03',
              section_footer: true,
              section: section_name
            }
          ])
      end

      it 'marks the first line as header and footer if is the only line in the section' do
        expect(convert_json("#{section_start}Hello world!#{section_end}")).to eq(
          [
            {
              offset: 0,
              content: [{ text: 'Hello world!' }],
              section: section_name,
              section_header: true
            },
            {
              offset: 56,
              content: [],
              section: section_name,
              section_duration: '01:03',
              section_footer: true
            }
          ])
      end

      it 'does not add sections attribute to lines after the section is closed' do
        expect(convert_json("#{section_start}Hello#{section_end}world")).to eq(
          [
            {
              offset: 0,
              content: [{ text: 'Hello' }],
              section: section_name,
              section_header: true
            },
            {
              offset: 49,
              content: [],
              section: section_name,
              section_duration: '01:03',
              section_footer: true
            },
            {
              offset: 91,
              content: [{ text: 'world' }]
            }
          ])
      end

      it 'ignores section_end marker if no section_start exists' do
        expect(convert_json("Hello #{section_end}world\nNext line")).to eq(
          [
            {
              offset: 0,
              content: [{ text: 'Hello world' }]
            },
            {
              offset: 54,
              content: [{ text: 'Next line' }]
            }
          ])
      end

      context 'when section name contains .-_ and capital letters' do
        let(:section_name) { 'a.Legit-SeCtIoN_namE' }

        it 'sanitizes the section name' do
          expect(convert_json("Hello#{section_start}world!")).to eq(
            [
              {
                offset: 0,
                content: [{ text: 'Hello' }]
              },
              {
                offset: 5,
                content: [{ text: 'world!' }],
                section: 'a-legit-section-name',
                section_header: true
              }
            ])
        end
      end

      context 'when section name includes $' do
        let(:section_name) { 'my_$ection' }

        it 'ignores the section' do
          expect(convert_json("#{section_start}hello")).to eq(
            [
              {
                offset: 0,
                content: [{ text: 'hello' }]
              }
            ])
        end
      end

      context 'when section name includes <' do
        let(:section_name) { '<a_tag>' }

        it 'ignores the section' do
          expect(convert_json("#{section_start}hello")).to eq(
            [
              {
                offset: 0,
                content: [{ text: 'hello' }]
              }
            ])
        end
      end

      it 'prints HTML tags as is' do
        trace = "#{section_start}section_end:1:2<div>hello</div>#{section_end}"
        expect(convert_json(trace)).to eq(
          [
            {
              offset: 0,
              content: [{ text: 'section_end:1:2<div>hello</div>' }],
              section: section_name,
              section_header: true
            },
            {
              offset: 75,
              content: [],
              section: section_name,
              section_duration: '01:03',
              section_footer: true
            }
          ])
      end

      context 'with nested section' do
        let(:nested_section_name) { 'prepare-script-nested' }
        let(:nested_section_duration) { 2.seconds }
        let(:nested_section_start_time) { Time.new(2019, 9, 17).utc }
        let(:nested_section_end_time) { nested_section_start_time + nested_section_duration }
        let(:nested_section_start) { "section_start:#{nested_section_start_time.to_i}:#{nested_section_name}\r\033[0K" }
        let(:nested_section_end) { "section_end:#{nested_section_end_time.to_i}:#{nested_section_name}\r\033[0K" }

        it 'adds multiple sections to the lines inside the nested section' do
          trace = "Hello#{section_start}foo#{nested_section_start}bar#{nested_section_end}baz#{section_end}world"

          expect(convert_json(trace)).to eq(
            [
              {
                offset: 0,
                content: [{ text: 'Hello' }]
              },
              {
                offset: 5,
                content: [{ text: 'foo' }],
                section: section_name,
                section_header: true
              },
              {
                offset: 52,
                content: [{ text: 'bar' }],
                section: nested_section_name,
                section_header: true
              },
              {
                offset: 106,
                content: [],
                section: nested_section_name,
                section_duration: '00:02',
                section_footer: true
              },
              {
                offset: 155,
                content: [{ text: 'baz' }],
                section: section_name
              },
              {
                offset: 158,
                content: [],
                section: section_name,
                section_duration: '01:03',
                section_footer: true
              },
              {
                offset: 200,
                content: [{ text: 'world' }]
              }
            ])
        end

        it 'adds multiple sections to the lines inside the nested section and closes all sections together' do
          trace = "Hello#{section_start}\e[91mfoo\e[0m#{nested_section_start}bar#{nested_section_end}#{section_end}"

          expect(convert_json(trace)).to eq(
            [
              {
                offset: 0,
                content: [{ text: 'Hello' }]
              },
              {
                offset: 5,
                content: [{ text: 'foo', style: 'term-fg-l-red' }],
                section: section_name,
                section_header: true
              },
              {
                offset: 61,
                content: [{ text: 'bar' }],
                section: nested_section_name,
                section_header: true
              },
              {
                offset: 115,
                content: [],
                section: nested_section_name,
                section_duration: '00:02',
                section_footer: true
              },
              {
                offset: 164,
                content: [],
                section: section_name,
                section_duration: '01:03',
                section_footer: true
              }
            ])
        end
      end

      context 'with section options' do
        let(:option_section_start) { "section_start:#{section_start_time.to_i}:#{section_name}[collapsed=true,unused_option=123]\r\033[0K" }

        it 'provides section options when set' do
          trace = "#{option_section_start}hello#{section_end}"
          expect(convert_json(trace)).to eq(
            [
              {
                offset: 0,
                content: [{ text: 'hello' }],
                section: section_name,
                section_header: true,
                section_options: {
                  'collapsed' => 'true',
                  'unused_option' => '123'
                }
              },
              {
                offset: 83,
                content: [],
                section: section_name,
                section_duration: '01:03',
                section_footer: true
              }
            ])
        end
      end
    end

    describe 'incremental updates' do
      let(:pass1_stream) { StringIO.new(pre_text) }
      let(:pass2_stream) { StringIO.new(pre_text + text) }
      let(:pass1) { subject.convert(pass1_stream) }
      let(:pass2) { subject.convert(pass2_stream, pass1.state) }

      context 'with split word' do
        let(:pre_text) { "\e[1mHello " }
        let(:text) { 'World' }

        let(:lines) do
          [
            { offset: 0, content: [{ text: 'Hello World', style: 'term-bold' }] }
          ]
        end

        it 'returns the full line' do
          expect(pass2.lines).to eq(lines)
          expect(pass2.append).to be_falsey
        end
      end

      context 'with split timestamp' do
        let(:pre_text) { "2024-05-14T11:19:19." }
        let(:text) { "899359Z 00O \e[1mHello World" }

        let(:lines) do
          [
            { offset: 0, timestamp: '2024-05-14T11:19:19.899359Z', content: [{ text: 'Hello World', style: 'term-bold' }] }
          ]
        end

        it 'returns the full line after a plain text partial timestamp' do
          expect(pass1.lines).to contain_exactly({ offset: 0, content: [{ text: "2024-05-14T11:19:19." }] })
          expect(pass2.lines).to eq(lines)
          expect(pass2.append).to be_falsey
        end
      end

      context 'with split word on second line' do
        let(:pre_text) { "Good\nmorning " }
        let(:text) { 'World' }

        let(:lines) do
          [
            { offset: 5, content: [{ text: 'morning World' }] }
          ]
        end

        it 'returns all lines since last partially processed line' do
          expect(pass2.lines).to eq(lines)
          expect(pass2.append).to be_truthy
        end

        context 'with timestamps' do
          let(:pre_text) { "2024-05-14T11:19:19.899359Z 00O Good\n2024-05-14T11:19:19.899359Z 00O morning " }

          let(:lines) do
            [
              { offset: 37, timestamp: '2024-05-14T11:19:19.899359Z', content: [{ text: 'morning World' }] }
            ]
          end

          it 'returns all lines since last partially processed line' do
            expect(pass2.lines).to eq(lines)
            expect(pass2.append).to be_truthy
          end
        end
      end

      context 'with split sequence across multiple lines' do
        let(:pre_text) { "\e[1mgood\nmorning\n" }
        let(:text) { "\e[3mworld" }

        let(:lines) do
          [
            { offset: 17, content: [{ text: 'world', style: 'term-bold term-italic' }] }
          ]
        end

        it 'returns the line since last partially processed line' do
          expect(pass2.lines).to eq(lines)
          expect(pass2.append).to be_truthy
        end
      end

      context 'with split partial sequence' do
        let(:pre_text) { "hello\e" }
        let(:text) { "[1m world" }

        let(:lines) do
          [
            { offset: 0, content: [
              { text: 'hello' },
              { text: ' world', style: 'term-bold' }
            ] }
          ]
        end

        it 'returns the line since last partially processed line' do
          expect(pass2.lines).to eq(lines)
          expect(pass2.append).to be_falsey
        end
      end

      context 'with split new line' do
        let(:pre_text) { "hello\r" }
        let(:text) { "\nworld" }

        let(:lines) do
          [
            { offset: 0, content: [{ text: 'hello' }] },
            { offset: 7, content: [{ text: 'world' }] }
          ]
        end

        it 'returns a blank line and the next line' do
          expect(pass2.lines).to eq(lines)
          expect(pass2.append).to be_falsey
        end
      end

      context 'with split section' do
        let(:section_name) { 'prepare-script' }
        let(:section_duration) { 63.seconds }
        let(:section_start_time) { Time.new(2019, 9, 17).utc }
        let(:section_end_time) { section_start_time + section_duration }
        let(:section_start) { "section_start:#{section_start_time.to_i}:#{section_name}\r\033[0K" }
        let(:section_end) { "section_end:#{section_end_time.to_i}:#{section_name}\r\033[0K" }

        context 'with split section body' do
          let(:pre_text) { "#{section_start}this is a header\nand " }
          let(:text) { "this\n is a body" }

          let(:lines) do
            [
              {
                offset: 61,
                content: [{ text: 'and this' }],
                section: 'prepare-script'
              },
              {
                offset: 70,
                content: [{ text: ' is a body' }],
                section: 'prepare-script'
              }
            ]
          end

          it 'returns the full line' do
            expect(pass2.lines).to eq(lines)
            expect(pass2.append).to be_truthy
          end
        end

        context 'with split section where header is also split' do
          let(:pre_text) { "#{section_start}this is " }
          let(:text) { "a header\nand body" }

          let(:lines) do
            [
              {
                offset: 0,
                content: [{ text: 'this is a header' }],
                section: section_name,
                section_header: true
              },
              {
                offset: 61,
                content: [{ text: 'and body' }],
                section: section_name
              }
            ]
          end

          it 'returns the full line' do
            expect(pass2.lines).to eq(lines)
            expect(pass2.append).to be_falsey
          end
        end

        context 'with split section end' do
          let(:pre_text) { "#{section_start}this is a header\nthe" }
          let(:text) { " body\nthe end#{section_end}" }

          let(:lines) do
            [
              {
                offset: 61,
                content: [{ text: 'the body' }],
                section: section_name
              },
              {
                offset: 70,
                content: [{ text: 'the end' }],
                section: section_name
              },
              {
                offset: 77,
                content: [],
                section: section_name,
                section_duration: '01:03',
                section_footer: true
              }
            ]
          end

          it 'returns the full line' do
            expect(pass2.lines).to eq(lines)
            expect(pass2.append).to be_truthy
          end
        end
      end
    end

    describe 'truncates' do
      let(:text) { 'Hello World' }
      let(:stream) { StringIO.new(text) }
      let(:convert) { described_class.convert(stream) }

      before do
        stream.seek(3, IO::SEEK_SET)
      end

      it 'returns truncated output' do
        expect(convert.truncated).to be_truthy
      end

      it 'does not append output' do
        expect(convert.append).to be_falsey
      end
    end

    context 'with timestamps' do
      it 'captures timestamp' do
        expect(convert_json('2024-05-14T11:19:19.899359Z 00O Hello')).to eq([
          { offset: 0, timestamp: '2024-05-14T11:19:19.899359Z', content: [{ text: 'Hello' }] }
        ])
      end

      context 'new lines' do
        it 'captures timestamp and adds new line when encountering \n' do
          expect(convert_json("2024-05-14T11:19:19.899359Z 00O Hello\n2024-05-14T11:19:20.000000Z 00O world")).to eq(
            [
              { offset: 0, timestamp: '2024-05-14T11:19:19.899359Z', content: [{ text: 'Hello' }] },
              { offset: 38, timestamp: '2024-05-14T11:19:20.000000Z', content: [{ text: 'world' }] }
            ])
        end

        it 'captures timestamp and adds new line when encountering \r\n' do
          expect(convert_json("2024-05-14T11:19:19.899359Z 00O Hello\r\n2024-05-14T11:19:20.899359Z 00O world")).to eq(
            [
              { offset: 0, timestamp: '2024-05-14T11:19:19.899359Z', content: [{ text: 'Hello' }] },
              { offset: 39, timestamp: '2024-05-14T11:19:20.899359Z', content: [{ text: 'world' }] }
            ])
        end

        it 'captures timestamp and ignores empty newlines' do
          expect(convert_json("2024-05-14T11:19:19.899359Z 00O Hello\n\n2024-05-14T11:19:20.899359Z 00O world")).to eq(
            [
              { offset: 0, timestamp: '2024-05-14T11:19:19.899359Z', content: [{ text: 'Hello' }] },
              { offset: 39, timestamp: '2024-05-14T11:19:20.899359Z', content: [{ text: 'world' }] }
            ])
          expect(convert_json("2024-05-14T11:19:19.899359Z 00O Hello\r\n\r\n2024-05-14T11:19:20.899359Z 00O world")).to eq(
            [
              { offset: 0, timestamp: '2024-05-14T11:19:19.899359Z', content: [{ text: 'Hello' }] },
              { offset: 41, timestamp: '2024-05-14T11:19:20.899359Z', content: [{ text: 'world' }] }
            ])
        end

        it 'captures timestamp and replaces the current line when encountering \r' do
          expect(convert_json("2024-05-14T11:19:19.899359Z 00O Hello \r2024-05-14T11:19:20.000000Z 00O world!")).to eq([
            { offset: 0, timestamp: '2024-05-14T11:19:20.000000Z', content: [{ text: 'world!' }] }
          ])
        end

        it 'joins lines when following line is marked as continuation' do
          expect(convert_json("2024-05-14T11:19:19.899359Z 00O Hello \n2024-05-14T11:19:20.000000Z 00O+world!")).to eq([
            { offset: 0, timestamp: '2024-05-14T11:19:19.899359Z', content: [{ text: 'Hello world!' }] }
          ])
        end

        it 'joins lines when following lines are marked as continuation' do
          text = [
            '2024-05-14T11:19:19.899359Z 00O Hello ',
            '2024-05-14T11:19:20.000000Z 00O+world, ',
            '2024-05-14T11:19:21.000000Z 00O+this is a second continuation',
            '2024-05-14T11:19:22.000000Z 00O This is a second line'
          ].join("\n")

          expect(convert_json(text)).to eq([
            {
              offset: 0, timestamp: '2024-05-14T11:19:19.899359Z',
              content: [{ text: 'Hello world, this is a second continuation' }]
            },
            {
              offset: 141, timestamp: '2024-05-14T11:19:22.000000Z',
              content: [{ text: 'This is a second line' }]
            }
          ])
        end
      end

      context 'with section markers' do
        let(:section_name) { 'prepare-script' }
        let(:section_duration) { 63.seconds }
        let(:section_start_time) { Time.new(2019, 9, 17).utc }
        let(:section_end_time) { section_start_time + section_duration }
        let(:section_start) { "section_start:#{section_start_time.to_i}:#{section_name}\r\033[0K" }
        let(:section_end) { "section_end:#{section_end_time.to_i}:#{section_name}\r\033[0K" }

        it 'marks the first line of the section as header' do
          expect(convert_json("2024-05-14T11:19:19.899359Z 00O Hello#{section_start}world!")).to eq(
            [
              {
                offset: 0,
                timestamp: '2024-05-14T11:19:19.899359Z',
                content: [{ text: 'Hello' }]
              },
              {
                offset: 37,
                timestamp: '2024-05-14T11:19:19.899359Z',
                content: [{ text: 'world!' }],
                section: 'prepare-script',
                section_header: true
              }
            ])
        end

        it 'does not mark the other lines of the section as header' do
          expect(convert_json("2024-05-14T11:19:19.899359Z 00O outside section#{section_start}Hello\n2024-05-14T11:19:20.899359Z 00O world!")).to eq(
            [
              {
                offset: 0,
                timestamp: '2024-05-14T11:19:19.899359Z',
                content: [{ text: 'outside section' }]
              },
              {
                offset: 47,
                timestamp: '2024-05-14T11:19:19.899359Z',
                content: [{ text: 'Hello' }],
                section: 'prepare-script',
                section_header: true
              },
              {
                offset: 97,
                timestamp: '2024-05-14T11:19:20.899359Z',
                content: [{ text: 'world!' }],
                section: 'prepare-script'
              }
            ])
        end

        it 'marks the last line of the section as footer' do
          expect(convert_json("2024-05-14T11:19:19.899359Z 00O #{section_start}Good\n2024-05-14T11:19:20.899359Z 00O morning\n2024-05-14T11:19:21.899359Z 00O world!\n2024-05-14T11:19:22.899359Z 00O #{section_end}")).to eq(
            [
              {
                offset: 0,
                timestamp: '2024-05-14T11:19:19.899359Z',
                content: [{ text: 'Good' }],
                section: section_name,
                section_header: true
              },
              {
                offset: 81,
                timestamp: '2024-05-14T11:19:20.899359Z',
                content: [{ text: 'morning' }],
                section: section_name
              },
              {
                offset: 121,
                timestamp: '2024-05-14T11:19:21.899359Z',
                content: [{ text: 'world!' }],
                section: section_name
              },
              {
                offset: 160,
                timestamp: '2024-05-14T11:19:22.899359Z',
                content: [],
                section_duration: '01:03',
                section_footer: true,
                section: section_name
              }
            ])
        end

        it 'marks the first line as header and footer if is the only line in the section' do
          expect(convert_json("#{section_start}Hello world!#{section_end}")).to eq(
            [
              {
                offset: 0,
                content: [{ text: 'Hello world!' }],
                section: section_name,
                section_header: true
              },
              {
                offset: 56,
                content: [],
                section: section_name,
                section_duration: '01:03',
                section_footer: true
              }
            ])
        end
      end
    end

    def convert_json(data)
      stream = StringIO.new(data)
      subject.convert(stream).lines
    end
  end
end
