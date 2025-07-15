# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Popen, feature_category: :shared do
  let(:path) { Rails.root.join('tmp').to_s }
  let(:klass) do
    Class.new(Object).tap do |c|
      c.send(:include, described_class)
    end
  end

  let(:output) { popen_result.first }
  let(:status) { popen_result.last }

  describe '.popen_with_detail' do
    let(:popen_result) { klass.new.popen_with_detail(cmd) }

    let(:cmd) { %W[#{Gem.ruby} -e $stdout.puts(1);$stderr.puts(2);exit(3)] }

    it { expect(popen_result.cmd).to eq(cmd) }
    it { expect(popen_result.stdout).to eq("1\n") }
    it { expect(popen_result.stderr).to eq("2\n") }
    it { expect(popen_result.status.exitstatus).to eq(3) }
    it { expect(popen_result.duration).to be_kind_of(Numeric) }
  end

  context 'with zero status' do
    let(:popen_result) { klass.new.popen(%w[ls], path) }

    it { expect(status).to be_zero }
    it { expect(output).to include('tests') }
  end

  context 'with non-zero status' do
    let(:popen_result) { klass.new.popen(%w[cat NOTHING], path) }

    it { expect(status).to eq(1) }
    it { expect(output).to include('No such file or directory') }
  end

  context 'with non-zero status with a kill' do
    let(:cmd) { [Gem.ruby, "-e", "thr = Thread.new { sleep 5 }; Process.kill(9, Process.pid); thr.join"] }
    let(:popen_result) { klass.new.popen(cmd) }

    it { expect(status).to eq(9) }
    it { expect(output).to be_empty }
  end

  context 'with unsafe string command' do
    it 'raises an error when it gets called with a string argument' do
      expect { klass.new.popen('ls', path) }.to raise_error(RuntimeError)
    end
  end

  context 'with unsafe array command' do
    it 'raises an error when it gets called with an unsafe array' do
      expect { klass.new.popen(['ls -l'], path) }.to raise_error(RuntimeError)
    end
  end

  context 'with custom options' do
    let(:vars) { { 'foobar' => 123, 'PWD' => path } }
    let(:options) { { chdir: path } }

    it 'calls popen3 with the provided environment variables' do
      expect(Open3).to receive(:popen3).with(vars, 'ls', options)

      klass.new.popen(%w[ls], path, { 'foobar' => 123 })
    end
  end

  context 'with a process that writes a lot of data to stderr' do
    let(:test_string) { 'The quick brown fox jumped over the lazy dog' }
    # The pipe buffer is typically 64K. This string is about 440K.
    let(:spew_command) { ['bash', '-c', "for i in {1..10000}; do echo '#{test_string}' 1>&2; done"] }

    it 'returns zero' do
      output, status = klass.new.popen(spew_command, path)

      expect(output).to include(test_string)
      expect(status).to eq(0)
    end
  end

  context 'without a directory argument' do
    let(:popen_result) { klass.new.popen(%w[ls]) }

    it { expect(status).to be_zero }
    it { expect(output).to include('spec') }
  end

  context 'when using stdin' do
    let(:popen_result) { klass.new.popen(%w[cat]) { |stdin| stdin.write 'hello' } }

    it { expect(status).to be_zero }
    it { expect(output).to eq('hello') }
  end

  context 'when binary is absent' do
    it 'raises error' do
      expect do
        klass.new.popen(%w[foobar])
      end.to raise_error(Errno::ENOENT)
    end
  end
end
