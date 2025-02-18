# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHook, feature_category: :webhooks do
  it_behaves_like 'a webhook', factory: :project_hook
end
