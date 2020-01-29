# frozen_string_literal: true

RSpec.shared_examples 'setting sentry error data' do
  it 'sets the sentry error data correctly' do
    aggregate_failures 'testing the sentry error is correct' do
      expect(error['id']).to eql sentry_error.to_global_id.to_s
      expect(error['sentryId']).to eql sentry_error.id.to_s
      expect(error['status']).to eql sentry_error.status.upcase
      expect(error['firstSeen']).to eql sentry_error.first_seen
      expect(error['lastSeen']).to eql sentry_error.last_seen
    end
  end
end
