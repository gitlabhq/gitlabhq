require 'spec_helper'

describe PluginWorker do
  include RepoHelpers

  let(:filename) { 'my_plugin.rb' }
  let(:data) { { 'event_name' => 'project_create' } }

  subject { described_class.new }

  describe '#perform' do
    it 'executes Gitlab::Plugin with expected values' do
      allow(Gitlab::Plugin).to receive(:execute).with(filename, data).and_return([true, ''])

      expect(subject.perform(filename, data)).to be_truthy
    end

    it 'logs message in case of plugin execution failure' do
      allow(Gitlab::Plugin).to receive(:execute).with(filename, data).and_return([false, 'permission denied'])

      expect(Gitlab::PluginLogger).to receive(:error)
      expect(subject.perform(filename, data)).to be_truthy
    end
  end
end
