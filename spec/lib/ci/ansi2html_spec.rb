require 'spec_helper'

describe Ci::Ansi2html, lib: true do
  subject { Ci::Ansi2html }

  it "prints non-ansi as-is" do
    expect(subject.convert("Hello")[:html]).to eq('Hello')
  end

  it "strips non-color-changing controll sequences" do
    expect(subject.convert("Hello \e[2Kworld")[:html]).to eq('Hello world')
  end

  it "prints simply red" do
    expect(subject.convert("\e[31mHello\e[0m")[:html]).to eq('<span class="term-fg-red">Hello</span>')
  end

  it "prints simply red without trailing reset" do
    expect(subject.convert("\e[31mHello")[:html]).to eq('<span class="term-fg-red">Hello</span>')
  end

  it "prints simply yellow" do
    expect(subject.convert("\e[33mHello\e[0m")[:html]).to eq('<span class="term-fg-yellow">Hello</span>')
  end

  it "prints default on blue" do
    expect(subject.convert("\e[39;44mHello")[:html]).to eq('<span class="term-bg-blue">Hello</span>')
  end

  it "prints red on blue" do
    expect(subject.convert("\e[31;44mHello")[:html]).to eq('<span class="term-fg-red term-bg-blue">Hello</span>')
  end

  it "resets colors after red on blue" do
    expect(subject.convert("\e[31;44mHello\e[0m world")[:html]).to eq('<span class="term-fg-red term-bg-blue">Hello</span> world')
  end

  it "performs color change from red/blue to yellow/blue" do
    expect(subject.convert("\e[31;44mHello \e[33mworld")[:html]).to eq('<span class="term-fg-red term-bg-blue">Hello </span><span class="term-fg-yellow term-bg-blue">world</span>')
  end

  it "performs color change from red/blue to yellow/green" do
    expect(subject.convert("\e[31;44mHello \e[33;42mworld")[:html]).to eq('<span class="term-fg-red term-bg-blue">Hello </span><span class="term-fg-yellow term-bg-green">world</span>')
  end

  it "performs color change from red/blue to reset to yellow/green" do
    expect(subject.convert("\e[31;44mHello\e[0m \e[33;42mworld")[:html]).to eq('<span class="term-fg-red term-bg-blue">Hello</span> <span class="term-fg-yellow term-bg-green">world</span>')
  end

  it "ignores unsupported codes" do
    expect(subject.convert("\e[51mHello\e[0m")[:html]).to eq('Hello')
  end

  it "prints light red" do
    expect(subject.convert("\e[91mHello\e[0m")[:html]).to eq('<span class="term-fg-l-red">Hello</span>')
  end

  it "prints default on light red" do
    expect(subject.convert("\e[101mHello\e[0m")[:html]).to eq('<span class="term-bg-l-red">Hello</span>')
  end

  it "performs color change from red/blue to default/blue" do
    expect(subject.convert("\e[31;44mHello \e[39mworld")[:html]).to eq('<span class="term-fg-red term-bg-blue">Hello </span><span class="term-bg-blue">world</span>')
  end

  it "performs color change from light red/blue to default/blue" do
    expect(subject.convert("\e[91;44mHello \e[39mworld")[:html]).to eq('<span class="term-fg-l-red term-bg-blue">Hello </span><span class="term-bg-blue">world</span>')
  end

  it "prints bold text" do
    expect(subject.convert("\e[1mHello")[:html]).to eq('<span class="term-bold">Hello</span>')
  end

  it "resets bold text" do
    expect(subject.convert("\e[1mHello\e[21m world")[:html]).to eq('<span class="term-bold">Hello</span> world')
    expect(subject.convert("\e[1mHello\e[22m world")[:html]).to eq('<span class="term-bold">Hello</span> world')
  end

  it "prints italic text" do
    expect(subject.convert("\e[3mHello")[:html]).to eq('<span class="term-italic">Hello</span>')
  end

  it "resets italic text" do
    expect(subject.convert("\e[3mHello\e[23m world")[:html]).to eq('<span class="term-italic">Hello</span> world')
  end

  it "prints underlined text" do
    expect(subject.convert("\e[4mHello")[:html]).to eq('<span class="term-underline">Hello</span>')
  end

  it "resets underlined text" do
    expect(subject.convert("\e[4mHello\e[24m world")[:html]).to eq('<span class="term-underline">Hello</span> world')
  end

  it "prints concealed text" do
    expect(subject.convert("\e[8mHello")[:html]).to eq('<span class="term-conceal">Hello</span>')
  end

  it "resets concealed text" do
    expect(subject.convert("\e[8mHello\e[28m world")[:html]).to eq('<span class="term-conceal">Hello</span> world')
  end

  it "prints crossed-out text" do
    expect(subject.convert("\e[9mHello")[:html]).to eq('<span class="term-cross">Hello</span>')
  end

  it "resets crossed-out text" do
    expect(subject.convert("\e[9mHello\e[29m world")[:html]).to eq('<span class="term-cross">Hello</span> world')
  end

  it "can print 256 xterm fg colors" do
    expect(subject.convert("\e[38;5;16mHello")[:html]).to eq('<span class="xterm-fg-16">Hello</span>')
  end

  it "can print 256 xterm fg colors on normal magenta background" do
    expect(subject.convert("\e[38;5;16;45mHello")[:html]).to eq('<span class="xterm-fg-16 term-bg-magenta">Hello</span>')
  end

  it "can print 256 xterm bg colors" do
    expect(subject.convert("\e[48;5;240mHello")[:html]).to eq('<span class="xterm-bg-240">Hello</span>')
  end

  it "can print 256 xterm bg colors on normal magenta foreground" do
    expect(subject.convert("\e[48;5;16;35mHello")[:html]).to eq('<span class="term-fg-magenta xterm-bg-16">Hello</span>')
  end

  it "prints bold colored text vividly" do
    expect(subject.convert("\e[1;31mHello\e[0m")[:html]).to eq('<span class="term-fg-l-red term-bold">Hello</span>')
  end

  it "prints bold light colored text correctly" do
    expect(subject.convert("\e[1;91mHello\e[0m")[:html]).to eq('<span class="term-fg-l-red term-bold">Hello</span>')
  end

  it "prints &lt;" do
    expect(subject.convert("<")[:html]).to eq('&lt;')
  end

  describe "incremental update" do
    shared_examples 'stateable converter' do
      let(:pass1) { subject.convert(pre_text) }
      let(:pass2) { subject.convert(pre_text + text, pass1[:state]) }

      it "to returns html to append" do
        expect(pass2[:append]).to be_truthy
        expect(pass2[:html]).to eq(html)
        expect(pass1[:text] + pass2[:text]).to eq(pre_text + text)
        expect(pass1[:html] + pass2[:html]).to eq(pre_html + html)
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
end
