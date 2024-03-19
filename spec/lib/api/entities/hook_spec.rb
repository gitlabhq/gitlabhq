# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Hook, feature_category: :webhooks do
  let(:hook) { create(:project_hook) }
  let(:with_url_variables) { true }
  let(:entity) { described_class.new(hook, with_url_variables: with_url_variables) }

  subject(:json) { entity.as_json }

  it 'exposes correct attributes' do
    expect(json.keys).to contain_exactly(:alert_status, :created_at, :disabled_until, :enable_ssl_verification, :id,
      :merge_requests_events, :push_events, :repository_update_events, :tag_push_events, :url, :url_variables,
      :custom_webhook_template
    )
  end

  context 'when `with_url_variables` is set to false' do
    let(:with_url_variables) { false }

    it 'does not expose `with_url_variables` field' do
      expect(json.keys).not_to include(:url_variables)
    end
  end
end
