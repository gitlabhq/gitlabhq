# frozen_string_literal: true

require 'spec_helper'

describe API::API do
  let(:user) { create(:user, last_activity_on: Date.yesterday) }

  describe 'Record user last activity in after hook' do
    # It does not matter which endpoint is used because last_activity_on should
    # be updated on every request. `/groups` is used as an example
    # to represent any API endpoint

    it 'updates the users last_activity_on date' do
      expect { get api('/groups', user) }.to change { user.reload.last_activity_on }.to(Date.today)
    end

    context 'when the the api_activity_logging feature is disabled' do
      it 'does not touch last_activity_on' do
        stub_feature_flags(api_activity_logging: false)

        expect { get api('/groups', user) }.not_to change { user.reload.last_activity_on }
      end
    end
  end
end
