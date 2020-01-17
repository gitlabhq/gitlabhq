# frozen_string_literal: true

require 'spec_helper'

describe GitlabShellWorker do
  let(:worker) { described_class.new }

  describe '#perform with add_key' do
    it 'calls add_key on Gitlab::Shell' do
      expect_next_instance_of(Gitlab::Shell) do |instance|
        expect(instance).to receive(:add_key).with('foo', 'bar')
      end
      worker.perform(:add_key, 'foo', 'bar')
    end
  end
end
