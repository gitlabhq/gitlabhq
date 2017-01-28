require 'spec_helper'

describe Gitlab::Ci::TraceReader do
  let(:path) { __FILE__ }
  let(:lines) { File.readlines(path) }
  let(:bytesize) { lines.sum(&:bytesize) }

  it 'returns last few lines' do
    10.times do
      subject = build_subject
      last_lines = random_lines

      expected = lines.last(last_lines).join
      result = subject.read(last_lines: last_lines)

      expect(result).to eq(expected)
      expect(result.encoding).to eq(Encoding.default_external)
    end
  end

  it 'returns everything if trying to get too many lines' do
    result = build_subject.read(last_lines: lines.size * 2)

    expect(result).to eq(lines.join)
    expect(result.encoding).to eq(Encoding.default_external)
  end

  it 'returns all contents if last_lines is not specified' do
    result = build_subject.read

    expect(result).to eq(lines.join)
    expect(result.encoding).to eq(Encoding.default_external)
  end

  it 'raises an error if not passing an integer for last_lines' do
    expect do
      build_subject.read(last_lines: lines)
    end.to raise_error(ArgumentError)
  end

  def random_lines
    Random.rand(lines.size) + 1
  end

  def random_buffer
    Random.rand(bytesize) + 1
  end

  def build_subject
    described_class.new(__FILE__, buffer_size: random_buffer)
  end
end
