# frozen_string_literal: true

RSpec.shared_examples_for 'a webhook type' do
  describe 'urlVariables field' do
    before do
      webhook.update!(
        url: 'https://my-webhook.example/token1234/webhookid5678',
        url_variables: {
          'token-mask' => 'token1234', 'id-mask' => 'webhookid5678'
        }
      )
    end

    it 'returns the URL variable masks only' do
      expect(resolve_field(:url_variables, webhook, current_user: current_user)).to match_array(
        [{ key: 'token-mask' }, { key: 'id-mask' }]
      )
    end
  end

  describe 'customHeaders field' do
    before do
      webhook.update!(
        custom_headers: {
          'X-Gitlab-Token' => 'gl-token12345', 'Content-Length' => '1048576'
        }
      )
    end

    it 'returns the custom header names only' do
      expect(resolve_field(:custom_headers, webhook, current_user: current_user)).to match_array(
        [{ key: 'X-Gitlab-Token' }, { key: 'Content-Length' }]
      )
    end
  end

  # Some events attributes don't have a NOT NULL constraint in postgres and may possibly be null
  # so nil is converted to false for consistency
  describe 'event trigger fields with nullable database fields' do
    before do
      webhook.update!(confidential_note_events: nil, tag_push_events: nil)
    end

    it 'converts nil confidential_note_events to false' do
      expect(resolve_field(:confidential_note_events, webhook, current_user: current_user)).to be(false)
    end

    it 'converts nil tag_push_events to false' do
      expect(resolve_field(:tag_push_events, webhook, current_user: current_user)).to be(false)
    end
  end

  describe 'webhook_events field' do
    subject(:webhook_events) { described_class.fields['webhookEvents'] }

    it { is_expected.to have_attributes(max_page_size: 20) }

    it 'limits field call count' do
      expect(webhook_events.extensions).to include(a_kind_of(::Gitlab::Graphql::Limit::FieldCallCount))
    end
  end
end
