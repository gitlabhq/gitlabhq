# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'doorkeeper/authorizations/new', feature_category: :system_access do
  include Devise::Test::ControllerHelpers

  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:application) { build_stubbed(:oauth_application, owner: user) }

  let(:pre_auth) do
    client = instance_double(Doorkeeper::OAuth::Client, name: 'Test App', uid: 'test-uid')
    allow(client).to receive(:application).and_return(application)
    instance_double(
      Doorkeeper::OAuth::PreAuthorization,
      client: client,
      redirect_uri: 'http://example.com/callback',
      state: 'test-state',
      response_type: 'code',
      scope: 'read_user',
      nonce: 'test-nonce',
      code_challenge: nil,
      code_challenge_method: nil,
      scopes: []
    )
  end

  before do
    assign(:pre_auth, pre_auth)
    allow(view).to receive_messages(
      current_user: user,
      brand_title: 'GitLab',
      content_security_policy_nonce: 'test-nonce'
    )
  end

  describe 'OAuth application creation time display' do
    context 'when application was created recently' do
      it 'displays correct time ago text without date conversion issue' do
        # Stub application to have been created 2 hours ago
        allow(application).to receive(:created_at).and_return(2.hours.ago)

        render

        # With the fix, time_ago_in_words(created_at) should show accurate time
        # Expected: should show "about 2 hours ago"
        # Bug was: time_ago_in_words(created_at.to_date) showed much longer time

        expect(rendered).to include('about 2 hours ago')
      end
    end

    context 'when application was created 30 minutes ago' do
      it 'displays correct time ago text' do
        # Stub application to have been created 30 minutes ago
        allow(application).to receive(:created_at).and_return(30.minutes.ago)

        render

        # Should show "about 1 hour ago" or "30 minutes ago", not many hours
        expect(rendered).to match(/(?:about 1 hour ago|30 minutes ago)/)
      end
    end

    context 'when application was created 1 hour ago' do
      it 'displays correct time ago text for 1 hour' do
        # Stub application to have been created 1 hour ago
        allow(application).to receive(:created_at).and_return(1.hour.ago)

        render

        expect(rendered).to include('about 1 hour ago')
      end
    end

    context 'when application was created yesterday' do
      it 'displays correct time ago text for older applications' do
        # Stub application to have been created 1 day ago
        allow(application).to receive(:created_at).and_return(1.day.ago)

        render

        expect(rendered).to include('1 day ago')
      end
    end

    context 'when application was created at a specific time today' do
      it 'calculates time difference from actual creation time, not beginning of day' do
        # This test specifically addresses the bug where .to_date was used
        # If created at 2:00 PM today, it should calculate from 2:00 PM, not 00:00:00

        creation_time = Time.current.beginning_of_day + 14.hours # 2:00 PM today
        current_time = Time.current.beginning_of_day + 16.hours  # 4:00 PM today

        travel_to current_time do
          # Stub application to have been created at 2:00 PM
          allow(application).to receive(:created_at).and_return(creation_time)
          render

          # Should show "about 2 hours ago", not "about 16 hours ago"
          expect(rendered).to include('about 2 hours ago')
        end
      end
    end
  end
end
