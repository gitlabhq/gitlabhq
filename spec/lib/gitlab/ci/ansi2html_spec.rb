require 'spec_helper'

describe Gitlab::Ci::Ansi2html do
  subject { described_class }

  it "prints non-ansi as-is" do
    expect(convert_html("Hello")).to eq('Hello')
  end

  it "strips non-color-changing controll sequences" do
    expect(convert_html("Hello \e[2Kworld")).to eq('Hello world')
  end

  it "prints simply red" do
    expect(convert_html("\e[31mHello\e[0m")).to eq('<span class="term-fg-red">Hello</span>')
  end

  it "prints simply red without trailing reset" do
    expect(convert_html("\e[31mHello")).to eq('<span class="term-fg-red">Hello</span>')
  end

  it "prints simply yellow" do
    expect(convert_html("\e[33mHello\e[0m")).to eq('<span class="term-fg-yellow">Hello</span>')
  end

  it "prints default on blue" do
    expect(convert_html("\e[39;44mHello")).to eq('<span class="term-bg-blue">Hello</span>')
  end

  it "prints red on blue" do
    expect(convert_html("\e[31;44mHello")).to eq('<span class="term-fg-red term-bg-blue">Hello</span>')
  end

  it "resets colors after red on blue" do
    expect(convert_html("\e[31;44mHello\e[0m world")).to eq('<span class="term-fg-red term-bg-blue">Hello</span> world')
  end

  it "performs color change from red/blue to yellow/blue" do
    expect(convert_html("\e[31;44mHello \e[33mworld")).to eq('<span class="term-fg-red term-bg-blue">Hello </span><span class="term-fg-yellow term-bg-blue">world</span>')
  end

  it "performs color change from red/blue to yellow/green" do
    expect(convert_html("\e[31;44mHello \e[33;42mworld")).to eq('<span class="term-fg-red term-bg-blue">Hello </span><span class="term-fg-yellow term-bg-green">world</span>')
  end

  it "performs color change from red/blue to reset to yellow/green" do
    expect(convert_html("\e[31;44mHello\e[0m \e[33;42mworld")).to eq('<span class="term-fg-red term-bg-blue">Hello</span> <span class="term-fg-yellow term-bg-green">world</span>')
  end

  it "ignores unsupported codes" do
    expect(convert_html("\e[51mHello\e[0m")).to eq('Hello')
  end

  it "prints light red" do
    expect(convert_html("\e[91mHello\e[0m")).to eq('<span class="term-fg-l-red">Hello</span>')
  end

  it "prints default on light red" do
    expect(convert_html("\e[101mHello\e[0m")).to eq('<span class="term-bg-l-red">Hello</span>')
  end

  it "performs color change from red/blue to default/blue" do
    expect(convert_html("\e[31;44mHello \e[39mworld")).to eq('<span class="term-fg-red term-bg-blue">Hello </span><span class="term-bg-blue">world</span>')
  end

  it "performs color change from light red/blue to default/blue" do
    expect(convert_html("\e[91;44mHello \e[39mworld")).to eq('<span class="term-fg-l-red term-bg-blue">Hello </span><span class="term-bg-blue">world</span>')
  end

  it "prints bold text" do
    expect(convert_html("\e[1mHello")).to eq('<span class="term-bold">Hello</span>')
  end

  it "resets bold text" do
    expect(convert_html("\e[1mHello\e[21m world")).to eq('<span class="term-bold">Hello</span> world')
    expect(convert_html("\e[1mHello\e[22m world")).to eq('<span class="term-bold">Hello</span> world')
  end

  it "prints italic text" do
    expect(convert_html("\e[3mHello")).to eq('<span class="term-italic">Hello</span>')
  end

  it "resets italic text" do
    expect(convert_html("\e[3mHello\e[23m world")).to eq('<span class="term-italic">Hello</span> world')
  end

  it "prints underlined text" do
    expect(convert_html("\e[4mHello")).to eq('<span class="term-underline">Hello</span>')
  end

  it "resets underlined text" do
    expect(convert_html("\e[4mHello\e[24m world")).to eq('<span class="term-underline">Hello</span> world')
  end

  it "prints concealed text" do
    expect(convert_html("\e[8mHello")).to eq('<span class="term-conceal">Hello</span>')
  end

  it "resets concealed text" do
    expect(convert_html("\e[8mHello\e[28m world")).to eq('<span class="term-conceal">Hello</span> world')
  end

  it "prints crossed-out text" do
    expect(convert_html("\e[9mHello")).to eq('<span class="term-cross">Hello</span>')
  end

  it "resets crossed-out text" do
    expect(convert_html("\e[9mHello\e[29m world")).to eq('<span class="term-cross">Hello</span> world')
  end

  it "can print 256 xterm fg colors" do
    expect(convert_html("\e[38;5;16mHello")).to eq('<span class="xterm-fg-16">Hello</span>')
  end

  it "can print 256 xterm fg colors on normal magenta background" do
    expect(convert_html("\e[38;5;16;45mHello")).to eq('<span class="xterm-fg-16 term-bg-magenta">Hello</span>')
  end

  it "can print 256 xterm bg colors" do
    expect(convert_html("\e[48;5;240mHello")).to eq('<span class="xterm-bg-240">Hello</span>')
  end

  it "can print 256 xterm fg bold colors" do
    expect(convert_html("\e[38;5;16;1mHello")).to eq('<span class="xterm-fg-16 term-bold">Hello</span>')
  end

  it "can print 256 xterm bg colors on normal magenta foreground" do
    expect(convert_html("\e[48;5;16;35mHello")).to eq('<span class="term-fg-magenta xterm-bg-16">Hello</span>')
  end

  it "prints bold colored text vividly" do
    expect(convert_html("\e[1;31mHello\e[0m")).to eq('<span class="term-fg-l-red term-bold">Hello</span>')
  end

  it "prints bold light colored text correctly" do
    expect(convert_html("\e[1;91mHello\e[0m")).to eq('<span class="term-fg-l-red term-bold">Hello</span>')
  end

  it "prints &lt;" do
    expect(convert_html("<")).to eq('&lt;')
  end

  it "replaces newlines with line break tags" do
    expect(convert_html("\n")).to eq('<br>')
  end

  it "groups carriage returns with newlines" do
    expect(convert_html("\r\n")).to eq('<br>')
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
      let(:html) { "<span class=\"term-bold\"></span><span class=\"term-bold\">World</span>" }

      it_behaves_like 'stateable converter'
    end

    context "with split sequence" do
      let(:pre_text) { "\e[1m" }
      let(:pre_html) { "<span class=\"term-bold\"></span>" }
      let(:text) { "Hello" }
      let(:html) { "<span class=\"term-bold\">Hello</span>" }

      it_behaves_like 'stateable converter'
    end

    context "with partial sequence" do
      let(:pre_text) { "Hello\e" }
      let(:pre_html) { "Hello" }
      let(:text) { "[1m World" }
      let(:html) { "<span class=\"term-bold\"> World</span>" }

      it_behaves_like 'stateable converter'
    end

    context 'with new line' do
      let(:pre_text) { "Hello\r" }
      let(:pre_html) { "Hello\r" }
      let(:text) { "\nWorld" }
      let(:html) { "<br>World" }

      it_behaves_like 'stateable converter'
    end
  end

  context "with section markers" do
    let(:section_name) { 'test_section' }
    let(:section_start_time) { Time.new(2017, 9, 20).utc }
    let(:section_duration) { 3.seconds }
    let(:section_end_time) { section_start_time + section_duration }
    let(:section_start) { "section_start:#{section_start_time.to_i}:#{section_name}\r\033[0K"}
    let(:section_end) { "section_end:#{section_end_time.to_i}:#{section_name}\r\033[0K"}
    let(:section_start_html) do
      '<div class="hidden" data-action="start"'\
      " data-timestamp=\"#{section_start_time.to_i}\" data-section=\"#{section_name}\">"\
      "#{section_start[0...-5]}</div>"
    end
    let(:section_end_html) do
      '<div class="hidden" data-action="end"'\
      " data-timestamp=\"#{section_end_time.to_i}\" data-section=\"#{section_name}\">"\
      "#{section_end[0...-5]}</div>"
    end

    shared_examples 'forbidden char in section_name' do
      it 'ignores sections' do
        text = "#{section_start}Some text#{section_end}"
        html = text.gsub("\033[0K", '').gsub('<', '&lt;')

        expect(convert_html(text)).to eq(html)
      end
    end

    shared_examples 'a legit section' do
      let(:text) { "#{section_start}Some text#{section_end}" }

      it 'prints light red' do
        text = "#{section_start}\e[91mHello\e[0m\n#{section_end}"
        html = %{#{section_start_html}<span class="term-fg-l-red">Hello</span><br>#{section_end_html}}

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
      let(:section_name) { 'my_$ection'}

      it_behaves_like 'forbidden char in section_name'
    end

    context 'section name includes <' do
      let(:section_name) { '<a_tag>'}

      it_behaves_like 'forbidden char in section_name'
    end

    context 'section name contains .-_' do
      let(:section_name) { 'a.Legit-SeCtIoN_namE' }

      it_behaves_like 'a legit section'
    end

    it 'do not allow XSS injections' do
      text = "#{section_start}section_end:1:2<script>alert('XSS Hack!');</script>#{section_end}"

      expect(convert_html(text)).not_to include('<script>')
    end
  end

  describe "truncates" do
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

  def convert_html(data)
    stream = StringIO.new(data)
    subject.convert(stream).html
  end
end
