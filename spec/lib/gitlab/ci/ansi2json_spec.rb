# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Ansi2json do
  subject { described_class }

  describe 'lines' do
    it 'prints non-ansi as-is' do
      expect(convert_json('Hello')).to eq([
        { offset: 0, content: [{ text: 'Hello' }] }
      ])
    end

    context 'new lines' do
      it 'adds new line when encountering \n' do
        expect(convert_json("Hello\nworld")).to eq([
          { offset: 0, content: [{ text: 'Hello' }] },
          { offset: 6, content: [{ text: 'world' }] }
        ])
      end

      it 'adds new line when encountering \r\n' do
        expect(convert_json("Hello\r\nworld")).to eq([
          { offset: 0, content: [{ text: 'Hello' }] },
          { offset: 7, content: [{ text: 'world' }] }
        ])
      end

      it 'replace the current line when encountering \r' do
        expect(convert_json("Hello\rworld")).to eq([
          { offset: 0, content: [{ text: 'world' }] }
        ])
      end
    end

    it 'recognizes color changing ANSI sequences' do
      expect(convert_json("\e[31mHello\e[0m")).to eq([
        { offset: 0, content: [{ text: 'Hello', style: 'term-fg-red' }] }
      ])
    end

    it 'recognizes color changing ANSI sequences across multiple lines' do
      expect(convert_json("\e[31mHello\nWorld\e[0m")).to eq([
        { offset: 0, content: [{ text: 'Hello', style: 'term-fg-red' }] },
        { offset: 11, content: [{ text: 'World', style: 'term-fg-red' }] }
      ])
    end

    it 'recognizes background and foreground colors' do
      expect(convert_json("\e[31;44mHello")).to eq([
        { offset: 0, content: [{ text: 'Hello', style: 'term-fg-red term-bg-blue' }] }
      ])
    end

    it 'recognizes style changes within the same line' do
      expect(convert_json("\e[31;44mHello\e[0m world")).to eq([
        { offset: 0, content: [
          { text: 'Hello', style: 'term-fg-red term-bg-blue' },
          { text: ' world' }
        ] }
      ])
    end

    context 'with section markers' do
      let(:section_name) { 'prepare-script' }
      let(:section_duration) { 63.seconds }
      let(:section_start_time) { Time.new(2019, 9, 17).utc }
      let(:section_end_time) { section_start_time + section_duration }
      let(:section_start) { "section_start:#{section_start_time.to_i}:#{section_name}\r\033[0K"}
      let(:section_end) { "section_end:#{section_end_time.to_i}:#{section_name}\r\033[0K"}

      it 'marks the first line of the section as header' do
        expect(convert_json("Hello#{section_start}world!")).to eq([
          {
            offset: 0,
            content: [{ text: 'Hello' }]
          },
          {
            offset: 5,
            content: [{ text: 'world!' }],
            section: 'prepare-script',
            section_header: true
          }
        ])
      end

      it 'does not marks the other lines of the section as header' do
        expect(convert_json("outside section#{section_start}Hello\nworld!")).to eq([
          {
            offset: 0,
            content: [{ text: 'outside section' }]
          },
          {
            offset: 15,
            content: [{ text: 'Hello' }],
            section: 'prepare-script',
            section_header: true
          },
          {
            offset: 65,
            content: [{ text: 'world!' }],
            section: 'prepare-script'
          }
        ])
      end

      it 'marks the last line of the section as footer' do
        expect(convert_json("#{section_start}Good\nmorning\nworld!#{section_end}")).to eq([
          {
            offset: 0,
            content: [{ text: 'Good' }],
            section: 'prepare-script',
            section_header: true
          },
          {
            offset: 49,
            content: [{ text: 'morning' }],
            section: 'prepare-script'
          },
          {
            offset: 57,
            content: [{ text: 'world!' }],
            section: 'prepare-script'
          },
          {
            offset: 63,
            content: [],
            section_duration: '01:03',
            section: 'prepare-script'
          }
        ])
      end

      it 'marks the first line as header and footer if is the only line in the section' do
        expect(convert_json("#{section_start}Hello world!#{section_end}")).to eq([
          {
            offset: 0,
            content: [{ text: 'Hello world!' }],
            section: 'prepare-script',
            section_header: true
          },
          {
            offset: 56,
            content: [],
            section: 'prepare-script',
            section_duration: '01:03'
          }
        ])
      end

      it 'does not add sections attribute to lines after the section is closed' do
        expect(convert_json("#{section_start}Hello#{section_end}world")).to eq([
          {
            offset: 0,
            content: [{ text: 'Hello' }],
            section: 'prepare-script',
            section_header: true
          },
          {
            offset: 49,
            content: [],
            section: 'prepare-script',
            section_duration: '01:03'
          },
          {
            offset: 91,
            content: [{ text: 'world' }]
          }
        ])
      end

      it 'ignores section_end marker if no section_start exists' do
        expect(convert_json("Hello #{section_end}world")).to eq([
          {
            offset: 0,
            content: [{ text: 'Hello world' }]
          }
        ])
      end

      context 'when section name contains .-_ and capital letters' do
        let(:section_name) { 'a.Legit-SeCtIoN_namE' }

        it 'sanitizes the section name' do
          expect(convert_json("Hello#{section_start}world!")).to eq([
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
          expect(convert_json("#{section_start}hello")).to eq([
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
          expect(convert_json("#{section_start}hello")).to eq([
            {
              offset: 0,
              content: [{ text: 'hello' }]
            }
          ])
        end
      end

      it 'prints HTML tags as is' do
        trace = "#{section_start}section_end:1:2<div>hello</div>#{section_end}"
        expect(convert_json(trace)).to eq([
          {
            offset: 0,
            content: [{ text: "section_end:1:2<div>hello</div>" }],
            section: 'prepare-script',
            section_header: true
          },
          {
            offset: 75,
            content: [],
            section: 'prepare-script',
            section_duration: '01:03'
          }
        ])
      end

      context 'with nested section' do
        let(:nested_section_name) { 'prepare-script-nested' }
        let(:nested_section_duration) { 2.seconds }
        let(:nested_section_start_time) { Time.new(2019, 9, 17).utc }
        let(:nested_section_end_time) { nested_section_start_time + nested_section_duration }
        let(:nested_section_start) { "section_start:#{nested_section_start_time.to_i}:#{nested_section_name}\r\033[0K"}
        let(:nested_section_end) { "section_end:#{nested_section_end_time.to_i}:#{nested_section_name}\r\033[0K"}

        it 'adds multiple sections to the lines inside the nested section' do
          trace = "Hello#{section_start}foo#{nested_section_start}bar#{nested_section_end}baz#{section_end}world"

          expect(convert_json(trace)).to eq([
              {
                offset: 0,
                content: [{ text: 'Hello' }]
              },
              {
                offset: 5,
                content: [{ text: 'foo' }],
                section: 'prepare-script',
                section_header: true
              },
              {
                offset: 52,
                content: [{ text: 'bar' }],
                section: 'prepare-script-nested',
                section_header: true
              },
              {
                offset: 106,
                content: [],
                section: 'prepare-script-nested',
                section_duration: '00:02'
              },
              {
                offset: 155,
                content: [{ text: 'baz' }],
                section: 'prepare-script'
              },
              {
                offset: 158,
                content: [],
                section: 'prepare-script',
                section_duration: '01:03'
              },
              {
                offset: 200,
                content: [{ text: 'world' }]
              }
            ])
        end

        it 'adds multiple sections to the lines inside the nested section and closes all sections together' do
          trace = "Hello#{section_start}\e[91mfoo\e[0m#{nested_section_start}bar#{nested_section_end}#{section_end}"

          expect(convert_json(trace)).to eq([
              {
                offset: 0,
                content: [{ text: 'Hello' }]
              },
              {
                offset: 5,
                content: [{ text: 'foo', style: 'term-fg-l-red' }],
                section: 'prepare-script',
                section_header: true
              },
              {
                offset: 61,
                content: [{ text: 'bar' }],
                section: 'prepare-script-nested',
                section_header: true
              },
              {
                offset: 115,
                content: [],
                section: 'prepare-script-nested',
                section_duration: '00:02'
              },
              {
                offset: 164,
                content: [],
                section: 'prepare-script',
                section_duration: '01:03'
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
        let(:text) { "World" }

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

      context 'with split word on second line' do
        let(:pre_text) { "Good\nmorning " }
        let(:text) { "World" }

        let(:lines) do
          [
            { offset: 5, content: [{ text: 'morning World' }] }
          ]
        end

        it 'returns all lines since last partially processed line' do
          expect(pass2.lines).to eq(lines)
          expect(pass2.append).to be_truthy
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
        let(:section_start) { "section_start:#{section_start_time.to_i}:#{section_name}\r\033[0K"}
        let(:section_end) { "section_end:#{section_end_time.to_i}:#{section_name}\r\033[0K"}

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
                section: 'prepare-script',
                section_header: true
              },
              {
                offset: 61,
                content: [{ text: 'and body' }],
                section: 'prepare-script'
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
                section: 'prepare-script'
              },
              {
                offset: 70,
                content: [{ text: 'the end' }],
                section: 'prepare-script'
              },
              {
                offset: 77,
                content: [],
                section: 'prepare-script',
                section_duration: '01:03'
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

    describe 'trucates' do
      let(:text) { "Hello World" }
      let(:stream) { StringIO.new(text) }
      let(:subject) { described_class.convert(stream) }

      before do
        stream.seek(3, IO::SEEK_SET)
      end

      it "returns truncated output" do
        expect(subject.truncated).to be_truthy
      end

      it "does not append output" do
        expect(subject.append).to be_falsey
      end
    end

    def convert_json(data)
      stream = StringIO.new(data)
      subject.convert(stream).lines
    end
  end
end
