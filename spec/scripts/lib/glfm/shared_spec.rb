# frozen_string_literal: true
require 'fast_spec_helper'
require 'tmpdir'
require_relative '../../../../scripts/lib/glfm/shared'

RSpec.describe Glfm::Shared, feature_category: :team_planning do
  let(:instance) do
    Class.new do
      include Glfm::Shared
    end.new
  end

  describe '#write_file' do
    it 'creates the file' do
      filename = Dir::Tmpname.create('basename') do |path|
        instance.write_file(path, 'test')
      end

      expect(File.read(filename)).to eq 'test'
    end
  end

  describe '#run_external_cmd' do
    it 'runs the external command' do
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

  describe '#dump_yaml_with_formatting' do
    it 'returns formatted yaml' do
      hash = { a: 'b' }
      yaml = instance.dump_yaml_with_formatting(hash, literal_scalars: true)
      expect(yaml).to eq("---\na: |-\n  b\n")
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
