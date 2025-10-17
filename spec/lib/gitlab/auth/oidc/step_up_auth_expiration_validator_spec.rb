# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Oidc::StepUpAuthExpirationValidator, feature_category: :system_access do
  let(:current_time) { Time.current }

  around do |example|
    travel_to(current_time) { example.run }
  end

  describe '.validate' do
    using RSpec::Parameterized::TableSyntax

    subject(:validator_result) { described_class.validate(step_up_session) }

    where(:step_up_session, :expected_valid, :expected_expired, :expected_message) do
      { 'exp_timestamp' => 30.minutes.from_now.to_i } | true  | false | 'Session valid'
      { 'exp_timestamp' => 1.hour.ago.to_i }          | true  | true  | 'Session expired'
      { 'exp_timestamp' => 1.second.ago.to_i }        | true  | true  | 'Session expired'
      nil                                             | false | false | 'No session data provided'
      'invalid'                                       | false | false | 'No session data provided'
      {}                                              | false | false | 'No expiration timestamp in session'
      { 'exp_timestamp' => nil }                      | false | false | 'No expiration timestamp in session'
      { 'exp_timestamp' => '' }                       | false | false | 'No expiration timestamp in session'
    end

    with_them do
      it { is_expected.to be_a(Gitlab::Auth::Oidc::StepUpAuthExpirationValidator::Result) }

      it 'returns expected result' do
        expect(validator_result).to be_a(Gitlab::Auth::Oidc::StepUpAuthExpirationValidator::Result)
        expect(validator_result).to have_attributes(
          valid?: expected_valid,
          expired?: expected_expired,
          message: expected_message)
      end
    end
  end
end
