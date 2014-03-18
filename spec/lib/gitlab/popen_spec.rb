require 'spec_helper'

describe 'Gitlab::Popen', no_db: true do
  let (:path) { Rails.root.join('tmp').to_s }

  before do
    @klass = Class.new(Object)
    @klass.send(:include, Gitlab::Popen)
  end

  context 'zero status' do
    before do
      @output, @status = @klass.new.popen(%W(ls), path)
    end

    it { @status.should be_zero }
    it { @output.should include('cache') }
  end

  context 'non-zero status' do
    before do
      @output, @status = @klass.new.popen(%W(cat NOTHING), path)
    end

    it { @status.should == 1 }
    it { @output.should include('No such file or directory') }
  end

  context 'unsafe string command' do
    it 'raises an error when it gets called with a string argument' do
      expect { @klass.new.popen('ls', path) }.to raise_error
    end
  end

  context 'without a directory argument' do
    before do
      @output, @status = @klass.new.popen(%W(ls))
    end

    it { @status.should be_zero }
    it { @output.should include('spec') }
  end

end

