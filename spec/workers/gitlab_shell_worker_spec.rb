require 'spec_helper'

describe GitlabShellWorker do
  let(:worker) { described_class.new }

  describe '#perform with add_key' do
    it 'calls add_key on Gitlab::Shell' do
      expect_any_instance_of(Gitlab::Shell).to receive(:add_key).with('foo', 'bar')
      worker.perform(:add_key, 'foo', 'bar')
    end
  end
end
