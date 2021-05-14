# frozen_string_literal: true
require 'spec_helper'

RSpec.describe WebHookWorker do
  include AfterNextHelpers

  let_it_be(:project_hook) { create(:project_hook) }
  let_it_be(:data) { { foo: 'bar' } }
  let_it_be(:hook_name) { 'push_hooks' }

  describe '#perform' do
    it 'delegates to WebHookService' do
      expect_next(WebHookService, project_hook, data.with_indifferent_access, hook_name).to receive(:execute)

      subject.perform(project_hook.id, data, hook_name)
    end
  end
end
