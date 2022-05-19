# frozen_string_literal: true
require 'fast_spec_helper'
require_relative '../../../../scripts/lib/glfm/shared'

RSpec.describe Glfm::Shared do
  let(:instance) do
    Class.new do
      include Glfm::Shared
    end.new
  end

  describe '#run_external_cmd' do
    it 'works' do
      expect(instance.run_external_cmd('echo "hello"')).to eq("hello\n")
    end

    context 'when command fails' do
      it 'raises error' do
        invalid_cmd = 'ls nonexistent_file'
        expect(instance).to receive(:warn).with(/Error running command `#{invalid_cmd}`/)
        expect(instance).to receive(:warn).with(/nonexistent_file.*no such file/i)
        expect { instance.run_external_cmd(invalid_cmd) }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#output' do
    # NOTE: The #output method is normally always mocked, to prevent output while the specs are
    # running. However, in order to provide code coverage for the method, we have to invoke
    # it at least once.
    it 'has code coverage' do
      allow(instance).to receive(:puts)
      instance.output('')
    end
  end
end
