# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountUserAuthMetric do
  context 'with all time frame' do
    let(:expected_value) { 2 }

    before do
      user = create(:user)
      user2 = create(:user)
      create(:authentication_event, user: user, provider: :ldapmain, result: :success)
      create(:authentication_event, user: user2, provider: :ldapsecondary, result: :success)
      create(:authentication_event, user: user2, provider: :group_saml, result: :success)
      create(:authentication_event, user: user2, provider: :group_saml, result: :success)
      create(:authentication_event, user: user, provider: :group_saml, result: :failed)
    end

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
  end

  context 'with 28d time frame' do
    let(:expected_value) { 1 }

    before do
      user = create(:user)
      user2 = create(:user)

      create(:authentication_event, created_at: 1.year.ago, user: user, provider: :ldapmain, result: :success)
      create(:authentication_event, created_at: 1.week.ago, user: user2, provider: :ldapsecondary, result: :success)
    end

    it_behaves_like 'a correct instrumented metric value', { time_frame: '28d', data_source: 'database' }
  end
end
