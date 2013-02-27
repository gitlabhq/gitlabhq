require 'spec_helper'

describe 'Gitlab::Popen', no_db: true do
  let (:path) { Rails.root.join('tmp').to_s }

  before do
    @klass = Class.new(Object)
    @klass.send(:include, Gitlab::Popen)
  end

  context 'zero status' do
    before do
      @output, @status = @klass.new.popen('ls', path)
    end

    it { @status.should be_zero }
    it { @output.should include('cache') }
  end

  context 'non-zero status' do
    before do
      @output, @status = @klass.new.popen('cat NOTHING', path)
    end

    it { @status.should == 1 }
    it { @output.should include('No such file or directory') }
  end
end

