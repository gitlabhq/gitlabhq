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

      expect(subject.read(last_lines: last_lines)).to eq(expected)
    end
  end

  it 'returns everything if trying to get too many lines' do
    expect(build_subject.read(last_lines: lines.size * 2)).to eq(lines.join)
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
