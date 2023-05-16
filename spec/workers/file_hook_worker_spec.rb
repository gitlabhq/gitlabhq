# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FileHookWorker, feature_category: :webhooks do
  include RepoHelpers

  let(:filename) { 'my_file_hook.rb' }
  let(:data) { { 'event_name' => 'project_create' } }

  subject { described_class.new }

  describe '#perform' do
    it 'executes Gitlab::FileHook with expected values' do
      allow(Gitlab::FileHook).to receive(:execute).with(filename, data).and_return([true, ''])

      expect(subject.perform(filename, data)).to be_truthy
    end

    it 'logs message in case of file_hook execution failure' do
      allow(Gitlab::FileHook).to receive(:execute).with(filename, data).and_return([false, 'permission denied'])

      expect(Gitlab::FileHookLogger).to receive(:error)
      expect(subject.perform(filename, data)).to be_truthy
    end
  end
end
