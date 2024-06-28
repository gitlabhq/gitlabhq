# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Hook, feature_category: :webhooks do
  let(:hook) { create(:project_hook) }
  let(:with_url_variables) { true }
  let(:with_custom_headers) { true }
  let(:entity) do
    described_class.new(hook, with_url_variables: with_url_variables, with_custom_headers: with_custom_headers)
  end

  subject(:json) { entity.as_json }

  it 'exposes correct attributes' do
    expect(json.keys).to contain_exactly(
      :id, :name, :description, :alert_status, :created_at, :disabled_until, :enable_ssl_verification, :tag_push_events,
      :merge_requests_events, :push_events, :repository_update_events, :url, :url_variables, :custom_webhook_template,
      :custom_headers, :branch_filter_strategy, :push_events_branch_filter
    )
  end

  context 'when `with_url_variables` is set to false' do
    let(:with_url_variables) { false }

    it 'does not expose `url_variables` field' do
      expect(json.keys).not_to include(:url_variables)
    end
  end

  context 'when `with_custom_headers` is set to false' do
    let(:with_custom_headers) { false }

    it 'does not expose `custom_headers` field' do
      expect(json.keys).not_to include(:custom_headers)
    end
  end
end
