# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Trace::Stream, :clean_gitlab_redis_cache do
  set(:build) { create(:ci_build, :running) }

  before do
    stub_feature_flags(ci_enable_live_trace: true)
  end

  describe 'delegates' do
    subject { described_class.new { nil } }

    it { is_expected.to delegate_method(:close).to(:stream) }
    it { is_expected.to delegate_method(:tell).to(:stream) }
    it { is_expected.to delegate_method(:seek).to(:stream) }
    it { is_expected.to delegate_method(:size).to(:stream) }
    it { is_expected.to delegate_method(:path).to(:stream) }
    it { is_expected.to delegate_method(:truncate).to(:stream) }
    it { is_expected.to delegate_method(:valid?).to(:stream).as(:present?) }
  end

  describe '#limit' do
    shared_examples_for 'limits' do
      it 'if size is larger we start from beginning' do
        stream.limit(20)

        expect(stream.tell).to eq(0)
      end

      it 'if size is smaller we start from the end' do
        stream.limit(2)

        expect(stream.raw).to eq("8")
      end

      context 'when the trace contains ANSI sequence and Unicode' do
        let(:stream) do
          described_class.new do
            File.open(expand_fixture_path('trace/ansi-sequence-and-unicode'))
          end
        end

        it 'forwards to the next linefeed, case 1' do
          stream.limit(7)

          result = stream.raw

          expect(result).to eq('')
          expect(result.encoding).to eq(Encoding.default_external)
        end

        it 'forwards to the next linefeed, case 2' do
          stream.limit(29)

          result = stream.raw

          expect(result).to eq("\e[01;32m許功蓋\e[0m\n")
          expect(result.encoding).to eq(Encoding.default_external)
        end

        # See https://gitlab.com/gitlab-org/gitlab-foss/issues/30796
        it 'reads in binary, output as Encoding.default_external' do
          stream.limit(52)

          result = stream.html

          expect(result).to eq(
            "<span>ヾ(´༎ຶД༎ຶ`)ﾉ<br/></span>"\
            "<span class=\"term-fg-green\">許功蓋</span>"\
            "<span><br/></span>")
          expect(result.encoding).to eq(Encoding.default_external)
        end
      end
    end

    context 'when stream is StringIO' do
      let(:stream) do
        described_class.new do
          StringIO.new((1..8).to_a.join("\n"))
        end
      end

      it_behaves_like 'limits'
    end

    context 'when stream is ChunkedIO' do
      let(:stream) do
        described_class.new do
          Gitlab::Ci::Trace::ChunkedIO.new(build).tap do |chunked_io|
            chunked_io.write((1..8).to_a.join("\n"))
            chunked_io.seek(0, IO::SEEK_SET)
          end
        end
      end

      it_behaves_like 'limits'
    end
  end

  describe '#append' do
    shared_examples_for 'appends' do
      it "truncates and append content" do
        stream.append(+"89", 4)
        stream.seek(0)

        expect(stream.size).to eq(6)
        expect(stream.raw).to eq("123489")
      end

      it 'appends in binary mode' do
        (+'😺').force_encoding('ASCII-8BIT').each_char.with_index do |byte, offset|
          stream.append(byte, offset)
        end

        stream.seek(0)

        expect(stream.size).to eq(4)
        expect(stream.raw).to eq('😺')
      end
    end

    context 'when stream is Tempfile' do
      let(:tempfile) { Tempfile.new }

      let(:stream) do
        described_class.new do
          tempfile.write("12345678")
          tempfile.rewind
          tempfile
        end
      end

      after do
        tempfile.unlink
      end

      it_behaves_like 'appends'
    end

    context 'when stream is ChunkedIO' do
      let(:stream) do
        described_class.new do
          Gitlab::Ci::Trace::ChunkedIO.new(build).tap do |chunked_io|
            chunked_io.write('12345678')
            chunked_io.seek(0, IO::SEEK_SET)
          end
        end
      end

      it_behaves_like 'appends'
    end
  end

  describe '#set' do
    shared_examples_for 'sets' do
      before do
        stream.set(+"8901")
      end

      it "overwrite content" do
        stream.seek(0)

        expect(stream.size).to eq(4)
        expect(stream.raw).to eq("8901")
      end
    end

    context 'when stream is StringIO' do
      let(:stream) do
        described_class.new do
          StringIO.new(+"12345678")
        end
      end

      it_behaves_like 'sets'
    end

    context 'when stream is ChunkedIO' do
      let(:stream) do
        described_class.new do
          Gitlab::Ci::Trace::ChunkedIO.new(build).tap do |chunked_io|
            chunked_io.write('12345678')
            chunked_io.seek(0, IO::SEEK_SET)
          end
        end
      end

      it_behaves_like 'sets'
    end
  end

  describe '#raw' do
    shared_examples_for 'sets' do
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

    let(:path) { __FILE__ }
    let(:lines) { File.readlines(path) }

    context 'when stream is File' do
      let(:stream) do
        described_class.new do
          File.open(path)
        end
      end

      it_behaves_like 'sets'
    end

    context 'when stream is ChunkedIO' do
      let(:stream) do
        described_class.new do
          Gitlab::Ci::Trace::ChunkedIO.new(build).tap do |chunked_io|
            chunked_io.write(File.binread(path))
            chunked_io.seek(0, IO::SEEK_SET)
          end
        end
      end

      it_behaves_like 'sets'
    end
  end

  describe '#html' do
    shared_examples_for 'htmls' do
      it "returns html" do
        expect(stream.html).to eq("<span>12<br/>34<br/>56</span>")
      end

      it "returns html for last line only" do
        expect(stream.html(last_lines: 1)).to eq("<span>56</span>")
      end
    end

    context 'when stream is StringIO' do
      let(:stream) do
        described_class.new do
          StringIO.new("12\n34\n56")
        end
      end

      it_behaves_like 'htmls'
    end

    context 'when stream is ChunkedIO' do
      let(:stream) do
        described_class.new do
          Gitlab::Ci::Trace::ChunkedIO.new(build).tap do |chunked_io|
            chunked_io.write("12\n34\n56")
            chunked_io.seek(0, IO::SEEK_SET)
          end
        end
      end

      it_behaves_like 'htmls'
    end
  end

  describe '#extract_coverage' do
    shared_examples_for 'extract_coverages' do
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
        let(:data) do
          <<~HEREDOC
            (98.39%) covered
            (98.29%) covered
          HEREDOC
        end

        let(:regex) { '\(\d+.\d+\%\) covered' }

        it 'returns the last matched coverage' do
          is_expected.to eq("98.29")
        end
      end

      context 'when BUFFER_SIZE is smaller than stream.size' do
        let(:data) { 'Coverage 1033 / 1051 LOC (98.29%) covered\n' }
        let(:regex) { '\(\d+.\d+\%\) covered' }

        before do
          stub_const('Gitlab::Ci::Trace::Stream::BUFFER_SIZE', 5)
        end

        it { is_expected.to eq("98.29") }
      end

      context 'when regex is multi-byte char' do
        let(:data) { '95.0 ゴッドファット\n' }
        let(:regex) { '\d+\.\d+ ゴッドファット' }

        before do
          stub_const('Gitlab::Ci::Trace::Stream::BUFFER_SIZE', 5)
        end

        it { is_expected.to eq('95.0') }
      end

      context 'when BUFFER_SIZE is equal to stream.size' do
        let(:data) { 'Coverage 1033 / 1051 LOC (98.29%) covered\n' }
        let(:regex) { '\(\d+.\d+\%\) covered' }

        before do
          stub_const('Gitlab::Ci::Trace::Stream::BUFFER_SIZE', data.length)
        end

        it { is_expected.to eq("98.29") }
      end

      context 'using a regex capture' do
        let(:data) { 'TOTAL      9926   3489    65%' }
        let(:regex) { 'TOTAL\s+\d+\s+\d+\s+(\d{1,3}\%)' }

        it { is_expected.to eq("65") }
      end

      context 'malicious regexp' do
        let(:data) { malicious_text }
        let(:regex) { malicious_regexp_re2 }

        include_examples 'malicious regexp'
      end

      context 'multi-line data with rooted regexp' do
        let(:data) { "\n65%\n" }
        let(:regex) { '^(\d+)\%$' }

        it { is_expected.to eq('65') }
      end

      context 'long line' do
        let(:data) { 'a' * 80000 + '100%' + 'a' * 80000 }
        let(:regex) { '\d+\%' }

        it { is_expected.to eq('100') }
      end

      context 'many lines' do
        let(:data) { "foo\n" * 80000 + "100%\n" + "foo\n" * 80000 }
        let(:regex) { '\d+\%' }

        it { is_expected.to eq('100') }
      end

      context 'empty regex' do
        let(:data) { 'foo' }
        let(:regex) { '' }

        it 'skips processing' do
          expect(stream).not_to receive(:read)

          is_expected.to be_nil
        end
      end

      context 'nil regex' do
        let(:data) { 'foo' }
        let(:regex) { nil }

        it 'skips processing' do
          expect(stream).not_to receive(:read)

          is_expected.to be_nil
        end
      end
    end

    subject { stream.extract_coverage(regex) }

    context 'when stream is StringIO' do
      let(:stream) do
        described_class.new do
          StringIO.new(data)
        end
      end

      it_behaves_like 'extract_coverages'
    end

    context 'when stream is ChunkedIO' do
      let(:stream) do
        described_class.new do
          Gitlab::Ci::Trace::ChunkedIO.new(build).tap do |chunked_io|
            chunked_io.write(data)
            chunked_io.seek(0, IO::SEEK_SET)
          end
        end
      end

      it_behaves_like 'extract_coverages'
    end
  end
end
