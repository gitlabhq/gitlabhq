# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeleteWithLimit do
  describe '.delete_with_limit' do
    it 'deletes a limited amount of rows' do
      create_list(:web_hook_log, 4)

      expect do
        WebHookLog.delete_with_limit(2)
      end.to change { WebHookLog.count }.by(-2)
    end
  end
end
