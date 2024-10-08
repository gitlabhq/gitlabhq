# frozen_string_literal: true

require 'fast_spec_helper'
require 'oj'
require_relative '../../../../app/models/concerns/checksummable'

RSpec.describe Gitlab::Ci::Ansi2html, feature_category: :continuous_integration do
  subject { described_class }

  shared_examples 'a working Ansi2html service' do |line_prefix: nil|
    it "prints non-ansi as-is" do
      expect(convert_html("#{line_prefix}Hello")).to eq('<span>Hello</span>')
    end

    context 'with ansi escape sequences' do
      it "strips non-color-changing control sequences" do
        expect(convert_html("#{line_prefix}Hello \e[2Kworld")).to eq('<span>Hello world</span>')
      end

      it "prints simply red" do
        expect(convert_html("#{line_prefix}\e[31mHello\e[0m")).to eq('<span class="term-fg-red">Hello</span>')
      end

      it "prints simply red without trailing reset" do
        expect(convert_html("#{line_prefix}\e[31mHello")).to eq('<span class="term-fg-red">Hello</span>')
      end

      it "prints simply yellow" do
        expect(convert_html("#{line_prefix}\e[33mHello\e[0m")).to eq('<span class="term-fg-yellow">Hello</span>')
      end

      it "prints default on blue" do
        expect(convert_html("#{line_prefix}\e[39;44mHello")).to eq('<span class="term-bg-blue">Hello</span>')
      end

      it "prints red on blue" do
        expect(convert_html("#{line_prefix}\e[31;44mHello")).to eq('<span class="term-fg-red term-bg-blue">Hello</span>')
      end

      it "resets colors after red on blue" do
        expect(convert_html("#{line_prefix}\e[31;44mHello\e[0m world")).to eq('<span class="term-fg-red term-bg-blue">Hello</span><span> world</span>')
      end

      it "performs color change from red/blue to yellow/blue" do
        expect(convert_html("#{line_prefix}\e[31;44mHello \e[33mworld")).to eq('<span class="term-fg-red term-bg-blue">Hello </span><span class="term-fg-yellow term-bg-blue">world</span>')
      end

      it "performs color change from red/blue to yellow/green" do
        expect(convert_html("#{line_prefix}\e[31;44mHello \e[33;42mworld")).to eq('<span class="term-fg-red term-bg-blue">Hello </span><span class="term-fg-yellow term-bg-green">world</span>')
      end

      it "performs color change from red/blue to reset to yellow/green" do
        expect(convert_html("#{line_prefix}\e[31;44mHello\e[0m \e[33;42mworld")).to eq('<span class="term-fg-red term-bg-blue">Hello</span><span> </span><span class="term-fg-yellow term-bg-green">world</span>')
      end

      it "ignores unsupported codes" do
        expect(convert_html("#{line_prefix}\e[51mHello\e[0m")).to eq('<span>Hello</span>')
      end

      it "prints light red" do
        expect(convert_html("#{line_prefix}\e[91mHello\e[0m")).to eq('<span class="term-fg-l-red">Hello</span>')
      end

      it "prints default on light red" do
        expect(convert_html("#{line_prefix}\e[101mHello\e[0m")).to eq('<span class="term-bg-l-red">Hello</span>')
      end

      it "performs color change from red/blue to default/blue" do
        expect(convert_html("#{line_prefix}\e[31;44mHello \e[39mworld")).to eq('<span class="term-fg-red term-bg-blue">Hello </span><span class="term-bg-blue">world</span>')
      end

      it "performs color change from light red/blue to default/blue" do
        expect(convert_html("#{line_prefix}\e[91;44mHello \e[39mworld")).to eq('<span class="term-fg-l-red term-bg-blue">Hello </span><span class="term-bg-blue">world</span>')
      end

      it "prints bold text" do
        expect(convert_html("#{line_prefix}\e[1mHello")).to eq('<span class="term-bold">Hello</span>')
      end

      it "resets bold text" do
        expect(convert_html("#{line_prefix}\e[1mHello\e[21m world")).to eq('<span class="term-bold">Hello</span><span> world</span>')
        expect(convert_html("#{line_prefix}\e[1mHello\e[22m world")).to eq('<span class="term-bold">Hello</span><span> world</span>')
      end

      it "prints italic text" do
        expect(convert_html("#{line_prefix}\e[3mHello")).to eq('<span class="term-italic">Hello</span>')
      end

      it "resets italic text" do
        expect(convert_html("#{line_prefix}\e[3mHello\e[23m world")).to eq('<span class="term-italic">Hello</span><span> world</span>')
      end

      it "prints underlined text" do
        expect(convert_html("#{line_prefix}\e[4mHello")).to eq('<span class="term-underline">Hello</span>')
      end

      it "resets underlined text" do
        expect(convert_html("#{line_prefix}\e[4mHello\e[24m world")).to eq('<span class="term-underline">Hello</span><span> world</span>')
      end

      it "prints concealed text" do
        expect(convert_html("#{line_prefix}\e[8mHello")).to eq('<span class="term-conceal">Hello</span>')
      end

      it "resets concealed text" do
        expect(convert_html("#{line_prefix}\e[8mHello\e[28m world")).to eq('<span class="term-conceal">Hello</span><span> world</span>')
      end

      it "prints crossed-out text" do
        expect(convert_html("#{line_prefix}\e[9mHello")).to eq('<span class="term-cross">Hello</span>')
      end

      it "resets crossed-out text" do
        expect(convert_html("#{line_prefix}\e[9mHello\e[29m world")).to eq('<span class="term-cross">Hello</span><span> world</span>')
      end

      it "can print 256 xterm fg colors" do
        expect(convert_html("#{line_prefix}\e[38;5;16mHello")).to eq('<span class="xterm-fg-16">Hello</span>')
      end

      it "can print 256 xterm fg colors on normal magenta background" do
        expect(convert_html("#{line_prefix}\e[38;5;16;45mHello")).to eq('<span class="xterm-fg-16 term-bg-magenta">Hello</span>')
      end

      it "can print 256 xterm bg colors" do
        expect(convert_html("#{line_prefix}\e[48;5;240mHello")).to eq('<span class="xterm-bg-240">Hello</span>')
      end

      it "can print 256 xterm fg bold colors" do
        expect(convert_html("#{line_prefix}\e[38;5;16;1mHello")).to eq('<span class="xterm-fg-16 term-bold">Hello</span>')
      end

      it "can print 256 xterm bg colors on normal magenta foreground" do
        expect(convert_html("#{line_prefix}\e[48;5;16;35mHello")).to eq('<span class="term-fg-magenta xterm-bg-16">Hello</span>')
      end

      it "prints bold colored text vividly" do
        expect(convert_html("#{line_prefix}\e[1;31mHello\e[0m")).to eq('<span class="term-fg-l-red term-bold">Hello</span>')
      end

      it "prints bold light colored text correctly" do
        expect(convert_html("#{line_prefix}\e[1;91mHello\e[0m")).to eq('<span class="term-fg-l-red term-bold">Hello</span>')
      end
    end

    it "prints &lt;" do
      expect(convert_html("#{line_prefix}<")).to eq('<span>&lt;</span>')
    end

    it "replaces newlines with line break tags" do
      expect(convert_html("#{line_prefix}\n#{line_prefix}")).to eq('<span><br/></span>')
    end

    it "groups carriage returns with newlines" do
      expect(convert_html("#{line_prefix}\r\n#{line_prefix}")).to eq('<span><br/></span>')
    end

    it "replaces consecutive linefeeds with line break tag" do
      expect(convert_html("#{line_prefix}\r\r\n#{line_prefix}")).to eq('<span><br/></span>')
    end

    it 'replaces invalid UTF-8 data' do
      expect(convert_html("#{line_prefix}UTF-8 dashes here: ───\n🐤🐤🐤🐤\xF0\x9F\x90\n")).to eq("<span>UTF-8 dashes here: ───<br/>🐤🐤🐤🐤�<br/></span>")
    end

    describe "incremental update" do
      shared_examples 'stateable converter' do
        let(:pass1_stream) { StringIO.new(pre_text) }
        let(:pass2_stream) { StringIO.new(pre_text + text) }
        let(:pass1) { subject.convert(pass1_stream) }
        let(:pass2) { subject.convert(pass2_stream, pass1.state) }

        it "to returns html to append" do
          expect(pass2.append).to be_truthy
          expect(pass2.html).to eq(html)
          expect(pass1.html + pass2.html).to eq(pre_html + html)
        end
      end

      context "with split word" do
        let(:pre_text) { "\e[1mHello" }
        let(:pre_html) { "<span class=\"term-bold\">Hello</span>" }
        let(:text) { "\e[1mWorld" }
        let(:html) { "<span class=\"term-bold\">World</span>" }

        it_behaves_like 'stateable converter'
      end

      context "with split sequence" do
        let(:pre_text) { "\e[1m" }
        let(:pre_html) { "" }
        let(:text) { "Hello" }
        let(:html) { "<span class=\"term-bold\">Hello</span>" }

        it_behaves_like 'stateable converter'
      end

      context "with partial sequence" do
        let(:pre_text) { "Hello\e" }
        let(:pre_html) { "<span>Hello</span>" }
        let(:text) { "[1m World" }
        let(:html) { "<span class=\"term-bold\"> World</span>" }

        it_behaves_like 'stateable converter'
      end

      context 'with new line' do
        let(:pre_text) { "Hello\r" }
        let(:pre_html) { "<span>Hello\r</span>" }
        let(:text) { "\nWorld" }
        let(:html) { "<span><br/>World</span>" }

        it_behaves_like 'stateable converter'
      end
    end

    context "with section markers" do
      let(:section_name) { 'test_section' }
      let(:section_start_time) { Time.new(2017, 9, 20).utc }
      let(:section_duration) { 3.seconds }
      let(:section_end_time) { section_start_time + section_duration }
      let(:section_start) { "section_start:#{section_start_time.to_i}:#{section_name}\r\033[0K" }
      let(:section_end) { "section_end:#{section_end_time.to_i}:#{section_name}\r\033[0K" }
      let(:section_start_html) do
        '<div class="section-start" ' \
        "data-timestamp=\"#{section_start_time.to_i}\" data-section=\"#{class_name(section_name)}\" " \
        'role="button"></div>'
      end

      let(:section_end_html) do
        "<div class=\"section-end\" data-section=\"#{class_name(section_name)}\"></div>"
      end

      shared_examples 'forbidden char in section_name' do
        it 'ignores sections' do
          text = "#{line_prefix}#{section_start}Some text#{section_end}"
          class_name_start = section_start.gsub("\033[0K", '').gsub('<', '&lt;')
          class_name_end = section_end.gsub("\033[0K", '').gsub('<', '&lt;')
          html = %(<span>#{class_name_start}Some text#{class_name_end}</span>)

          expect(convert_html(text)).to eq(html)
        end
      end

      shared_examples 'a legit section' do
        let(:text) { "#{line_prefix}#{section_start}Some text#{section_end}" }

        it 'prints light red' do
          text = "#{section_start}\e[91mHello\e[0m\nLine 1\nLine 2\nLine 3\n#{section_end}"
          header = %(<span class="term-fg-l-red section section-header js-s-#{class_name(section_name)}">Hello</span>)
          line_break = %(<span class="section section-header js-s-#{class_name(section_name)}"><br/></span>)
          output_line = %(<span class="section line js-s-#{class_name(section_name)}">Line 1<br/>Line 2<br/>Line 3<br/></span>)
          html = "#{section_start_html}#{header}#{line_break}#{output_line}#{section_end_html}"

          expect(convert_html(text)).to eq(html)
        end

        it 'begins with a section_start html marker' do
          expect(convert_html(text)).to start_with(section_start_html)
        end

        it 'ends with a section_end html marker' do
          expect(convert_html(text)).to end_with(section_end_html)
        end
      end

      it_behaves_like 'a legit section'

      context 'section name includes $' do
        let(:section_name) { 'my_$ection' }

        it_behaves_like 'forbidden char in section_name'
      end

      context 'section name includes <' do
        let(:section_name) { '<a_tag>' }

        it_behaves_like 'forbidden char in section_name'
      end

      context 'section name contains .-_' do
        let(:section_name) { 'a.Legit-SeCtIoN_namE' }

        it_behaves_like 'a legit section'
      end

      it 'do not allow XSS injections' do
        text = "#{line_prefix}#{section_start}section_end:1:2<script>alert('XSS Hack!');</script>#{section_end}"

        expect(convert_html(text)).not_to include('<script>')
      end
    end

    describe "truncates" do
      let(:text) { "#{line_prefix}Hello World" }
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
  end

  it_behaves_like 'a working Ansi2html service'
  it_behaves_like 'a working Ansi2html service', line_prefix: '2024-05-14T11:19:19.899359Z 00O '

  context 'with timestamps' do
    let(:timestamp) { '2024-05-14T11:19:19.899359Z 00O ' }

    it "joins lines when following lines are marked as continuation" do
      text = [
        '2024-05-14T11:19:19.899359Z 00O Hello ',
        '2024-05-14T11:19:20.000000Z 00O+world, ',
        '2024-05-14T11:19:21.000000Z 00O+this is a second continuation',
        '2024-05-14T11:19:22.000000Z 00O This is a second line'
      ].join("\n")

      expect(convert_html(text))
        .to eq('<span>Hello world, this is a second continuation<br/>This is a second line</span>')
    end
  end

  def convert_html(data)
    stream = StringIO.new(data)
    subject.convert(stream).html
  end

  def class_name(section)
    subject::Converter.new.section_to_class_name(section)
  end
end
