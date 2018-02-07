require 'spec_helper'

describe Gitlab::Popen do
  let(:path) { Rails.root.join('tmp').to_s }

  before do
    @klass = Class.new(Object)
    @klass.send(:include, described_class)
  end

  describe '.popen_with_detail' do
    subject { @klass.new.popen_with_detail(cmd) }

    let(:cmd) { %W[#{Gem.ruby} -e $stdout.puts(1);$stderr.puts(2);exit(3)] }

    it { expect(subject.cmd).to eq(cmd) }
    it { expect(subject.stdout).to eq("1\n") }
    it { expect(subject.stderr).to eq("2\n") }
    it { expect(subject.status.exitstatus).to eq(3) }
    it { expect(subject.duration).to be_kind_of(Numeric) }
  end

  context 'zero status' do
    before do
      @output, @status = @klass.new.popen(%w(ls), path)
    end

    it { expect(@status).to be_zero }
    it { expect(@output).to include('tests') }
  end

  context 'non-zero status' do
    before do
      @output, @status = @klass.new.popen(%w(cat NOTHING), path)
    end

    it { expect(@status).to eq(1) }
    it { expect(@output).to include('No such file or directory') }
  end

  context 'unsafe string command' do
    it 'raises an error when it gets called with a string argument' do
      expect { @klass.new.popen('ls', path) }.to raise_error(RuntimeError)
    end
  end

  context 'with custom options' do
    let(:vars) { { 'foobar' => 123, 'PWD' => path } }
    let(:options) { { chdir: path } }

    it 'calls popen3 with the provided environment variables' do
      expect(Open3).to receive(:popen3).with(vars, 'ls', options)

      @output, @status = @klass.new.popen(%w(ls), path, { 'foobar' => 123 })
    end
  end

  context 'without a directory argument' do
    before do
      @output, @status = @klass.new.popen(%w(ls))
    end

    it { expect(@status).to be_zero }
    it { expect(@output).to include('spec') }
  end

  context 'use stdin' do
    before do
      @output, @status = @klass.new.popen(%w[cat]) { |stdin| stdin.write 'hello' }
    end

    it { expect(@status).to be_zero }
    it { expect(@output).to eq('hello') }
  end
end
