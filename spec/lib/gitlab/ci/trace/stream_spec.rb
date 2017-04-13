require 'spec_helper'

describe Gitlab::Ci::Trace::Stream do
  describe 'delegates' do
    subject { described_class.new { StringIO.new } }

    it { is_expected.to delegate_method(:close).to(:stream) }
    it { is_expected.to delegate_method(:tell).to(:stream) }
    it { is_expected.to delegate_method(:seek).to(:stream) }
    it { is_expected.to delegate_method(:size).to(:stream) }
    it { is_expected.to delegate_method(:path).to(:stream) }
    it { is_expected.to delegate_method(:truncate).to(:stream) }
    it { is_expected.to delegate_method(:valid?).to(:stream).as(:present?) }
    it { is_expected.to delegate_method(:file?).to(:path).as(:present?) }
  end

  describe '#limit' do
    let(:stream) do
      described_class.new do
        StringIO.new((1..8).to_a.join("\n"))
      end
    end

    it 'if size is larger we start from beginning' do
      stream.limit(20)

      expect(stream.tell).to eq(0)
    end

    it 'if size is smaller we start from the end' do
      stream.limit(2)

      expect(stream.raw).to eq("7\n8")
    end

    context 'when the trace contains ANSI sequence and Unicode' do
      let(:trace_path) do
        expand_fixture_path('trace/ansi-sequence-and-unicode')
      end

      let(:stream) { described_class.new { File.open(trace_path) } }
      let(:content) { File.read(trace_path) }

      it 'forwards to the next linefeed, case 1' do
        stream.limit(7)

        expect(stream.raw).to eq(content.lines.last)
      end

      it 'forwards to the next linefeed, case 2' do
        stream.limit(29)

        expect(stream.raw).to eq(content.lines.last(2).join)
      end
    end
  end

  describe '#append' do
    let(:stream) do
      described_class.new do
        StringIO.new("12345678")
      end
    end

    it "truncates and append content" do
      stream.append("89", 4)
      stream.seek(0)

      expect(stream.size).to eq(6)
      expect(stream.raw).to eq("123489")
    end
  end

  describe '#set' do
    let(:stream) do
      described_class.new do
        StringIO.new("12345678")
      end
    end

    before do
      stream.set("8901")
    end

    it "overwrite content" do
      stream.seek(0)

      expect(stream.size).to eq(4)
      expect(stream.raw).to eq("8901")
    end
  end

  describe '#raw' do
    let(:path) { __FILE__ }
    let(:lines) { File.readlines(path) }
    let(:stream) do
      described_class.new do
        File.open(path)
      end
    end

    it 'returns all contents if last_lines is not specified' do
      result = stream.raw

      expect(result).to eq(lines.join)
      expect(result.encoding).to eq(Encoding.default_external)
    end

    context 'limit max lines' do
      before do
        # specifying BUFFER_SIZE forces to seek backwards
        allow(described_class).to receive(:BUFFER_SIZE)
          .and_return(2)
      end

      it 'returns last few lines' do
        result = stream.raw(last_lines: 2)

        expect(result).to eq(lines.last(2).join)
        expect(result.encoding).to eq(Encoding.default_external)
      end

      it 'returns everything if trying to get too many lines' do
        result = stream.raw(last_lines: lines.size * 2)

        expect(result).to eq(lines.join)
        expect(result.encoding).to eq(Encoding.default_external)
      end
    end
  end

  describe '#html_with_state' do
    let(:stream) do
      described_class.new do
        StringIO.new("1234")
      end
    end

    it 'returns html content with state' do
      result = stream.html_with_state

      expect(result.html).to eq("1234")
    end

    context 'follow-up state' do
      let!(:last_result) { stream.html_with_state }

      before do
        stream.append("5678", 4)
        stream.seek(0)
      end

      it "returns appended trace" do
        result = stream.html_with_state(last_result.state)

        expect(result.append).to be_truthy
        expect(result.html).to eq("5678")
      end
    end
  end

  describe '#html' do
    let(:stream) do
      described_class.new do
        StringIO.new("12\n34\n56")
      end
    end

    it "returns html" do
      expect(stream.html).to eq("12<br>34<br>56")
    end

    it "returns html for last line only" do
      expect(stream.html(last_lines: 1)).to eq("56")
    end
  end

  describe '#extract_coverage' do
    let(:stream) do
      described_class.new do
        StringIO.new(data)
      end
    end

    subject { stream.extract_coverage(regex) }

    context 'valid content & regex' do
      let(:data) { 'Coverage 1033 / 1051 LOC (98.29%) covered' }
      let(:regex) { '\(\d+.\d+\%\) covered' }

      it { is_expected.to eq("98.29") }
    end

    context 'valid content & bad regex' do
      let(:data) { 'Coverage 1033 / 1051 LOC (98.29%) covered\n' }
      let(:regex) { 'very covered' }

      it { is_expected.to be_nil }
    end

    context 'no coverage content & regex' do
      let(:data) { 'No coverage for today :sad:' }
      let(:regex) { '\(\d+.\d+\%\) covered' }

      it { is_expected.to be_nil }
    end

    context 'multiple results in content & regex' do
      let(:data) { ' (98.39%) covered. (98.29%) covered' }
      let(:regex) { '\(\d+.\d+\%\) covered' }

      it { is_expected.to eq("98.29") }
    end

    context 'using a regex capture' do
      let(:data) { 'TOTAL      9926   3489    65%' }
      let(:regex) { 'TOTAL\s+\d+\s+\d+\s+(\d{1,3}\%)' }

      it { is_expected.to eq("65") }
    end
  end
end
