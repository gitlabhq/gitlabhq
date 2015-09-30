require 'spec_helper'

describe Ci::Ansi2html do
  subject { Ci::Ansi2html }

  it "prints non-ansi as-is" do
    expect(subject.convert("Hello")).to eq('Hello')
  end

  it "strips non-color-changing controll sequences" do
    expect(subject.convert("Hello \e[2Kworld")).to eq('Hello world')
  end

  it "prints simply red" do
    expect(subject.convert("\e[31mHello\e[0m")).to eq('<span class="term-fg-red">Hello</span>')
  end

  it "prints simply red without trailing reset" do
    expect(subject.convert("\e[31mHello")).to eq('<span class="term-fg-red">Hello</span>')
  end

  it "prints simply yellow" do
    expect(subject.convert("\e[33mHello\e[0m")).to eq('<span class="term-fg-yellow">Hello</span>')
  end

  it "prints default on blue" do
    expect(subject.convert("\e[39;44mHello")).to eq('<span class="term-bg-blue">Hello</span>')
  end

  it "prints red on blue" do
    expect(subject.convert("\e[31;44mHello")).to eq('<span class="term-fg-red term-bg-blue">Hello</span>')
  end

  it "resets colors after red on blue" do
    expect(subject.convert("\e[31;44mHello\e[0m world")).to eq('<span class="term-fg-red term-bg-blue">Hello</span> world')
  end

  it "performs color change from red/blue to yellow/blue" do
    expect(subject.convert("\e[31;44mHello \e[33mworld")).to eq('<span class="term-fg-red term-bg-blue">Hello </span><span class="term-fg-yellow term-bg-blue">world</span>')
  end

  it "performs color change from red/blue to yellow/green" do
    expect(subject.convert("\e[31;44mHello \e[33;42mworld")).to eq('<span class="term-fg-red term-bg-blue">Hello </span><span class="term-fg-yellow term-bg-green">world</span>')
  end

  it "performs color change from red/blue to reset to yellow/green" do
    expect(subject.convert("\e[31;44mHello\e[0m \e[33;42mworld")).to eq('<span class="term-fg-red term-bg-blue">Hello</span> <span class="term-fg-yellow term-bg-green">world</span>')
  end

  it "ignores unsupported codes" do
    expect(subject.convert("\e[51mHello\e[0m")).to eq('Hello')
  end

  it "prints light red" do
    expect(subject.convert("\e[91mHello\e[0m")).to eq('<span class="term-fg-l-red">Hello</span>')
  end

  it "prints default on light red" do
    expect(subject.convert("\e[101mHello\e[0m")).to eq('<span class="term-bg-l-red">Hello</span>')
  end

  it "performs color change from red/blue to default/blue" do
    expect(subject.convert("\e[31;44mHello \e[39mworld")).to eq('<span class="term-fg-red term-bg-blue">Hello </span><span class="term-bg-blue">world</span>')
  end

  it "performs color change from light red/blue to default/blue" do
    expect(subject.convert("\e[91;44mHello \e[39mworld")).to eq('<span class="term-fg-l-red term-bg-blue">Hello </span><span class="term-bg-blue">world</span>')
  end

  it "prints bold text" do
    expect(subject.convert("\e[1mHello")).to eq('<span class="term-bold">Hello</span>')
  end

  it "resets bold text" do
    expect(subject.convert("\e[1mHello\e[21m world")).to eq('<span class="term-bold">Hello</span> world')
    expect(subject.convert("\e[1mHello\e[22m world")).to eq('<span class="term-bold">Hello</span> world')
  end

  it "prints italic text" do
    expect(subject.convert("\e[3mHello")).to eq('<span class="term-italic">Hello</span>')
  end

  it "resets italic text" do
    expect(subject.convert("\e[3mHello\e[23m world")).to eq('<span class="term-italic">Hello</span> world')
  end

  it "prints underlined text" do
    expect(subject.convert("\e[4mHello")).to eq('<span class="term-underline">Hello</span>')
  end

  it "resets underlined text" do
    expect(subject.convert("\e[4mHello\e[24m world")).to eq('<span class="term-underline">Hello</span> world')
  end

  it "prints concealed text" do
    expect(subject.convert("\e[8mHello")).to eq('<span class="term-conceal">Hello</span>')
  end

  it "resets concealed text" do
    expect(subject.convert("\e[8mHello\e[28m world")).to eq('<span class="term-conceal">Hello</span> world')
  end

  it "prints crossed-out text" do
    expect(subject.convert("\e[9mHello")).to eq('<span class="term-cross">Hello</span>')
  end

  it "resets crossed-out text" do
    expect(subject.convert("\e[9mHello\e[29m world")).to eq('<span class="term-cross">Hello</span> world')
  end

  it "can print 256 xterm fg colors" do
    expect(subject.convert("\e[38;5;16mHello")).to eq('<span class="xterm-fg-16">Hello</span>')
  end

  it "can print 256 xterm fg colors on normal magenta background" do
    expect(subject.convert("\e[38;5;16;45mHello")).to eq('<span class="xterm-fg-16 term-bg-magenta">Hello</span>')
  end

  it "can print 256 xterm bg colors" do
    expect(subject.convert("\e[48;5;240mHello")).to eq('<span class="xterm-bg-240">Hello</span>')
  end

  it "can print 256 xterm bg colors on normal magenta foreground" do
    expect(subject.convert("\e[48;5;16;35mHello")).to eq('<span class="term-fg-magenta xterm-bg-16">Hello</span>')
  end

  it "prints bold colored text vividly" do
    expect(subject.convert("\e[1;31mHello\e[0m")).to eq('<span class="term-fg-l-red term-bold">Hello</span>')
  end

  it "prints bold light colored text correctly" do
    expect(subject.convert("\e[1;91mHello\e[0m")).to eq('<span class="term-fg-l-red term-bold">Hello</span>')
  end
end
