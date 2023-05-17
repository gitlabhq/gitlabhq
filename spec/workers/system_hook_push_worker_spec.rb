# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemHookPushWorker, feature_category: :source_code_management do
  include RepoHelpers

  subject { described_class.new }

  describe '#perform' do
    it 'executes SystemHooksService with expected values' do
      push_data = double('push_data')
      system_hook_service = double('system_hook_service')

      expect(SystemHooksService).to receive(:new).and_return(system_hook_service)
      expect(system_hook_service).to receive(:execute_hooks).with(push_data, :push_hooks)

      subject.perform(push_data, :push_hooks)
    end
  end
end
