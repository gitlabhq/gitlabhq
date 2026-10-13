# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Getting the contribution calendar of a user', feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be_with_reload(:target_user) { create(:user, timezone: 'Asia/Tokyo') }
  let_it_be(:project) { create(:project, :public) }

  # 20:00 UTC is 05:00 on the next day in Tokyo, so the day the push lands on
  # only comes out right when the calendar counts in the contributor's timezone.
  let_it_be(:pushed_at) { 2.days.ago.utc.change(hour: 20) }
  let_it_be(:push_event) { create(:push_event, project: project, author: target_user, created_at: pushed_at) }

  let_it_be(:path) { %i[user contribution_calendar] }

  let(:user_params) { { username: target_user.username } }
  let(:fields) { 'utcOffset timezone totalCount days { date count }' }
  let(:query) { graphql_query_for(:user, user_params, query_graphql_field(:contribution_calendar, fields)) }

  let(:calendar) do
    post_graphql(query, current_user: current_user)

    graphql_data_at(*path)
  end

  shared_examples 'the calendar of the target user' do
    it 'returns the offset and identifier of the timezone of the target user' do
      expect(calendar).to include('utcOffset' => 32_400, 'timezone' => 'Asia/Tokyo')
    end

    it 'counts the contributions on the days of the timezone of the target user' do
      expect(calendar['totalCount']).to eq(1)
      expect(calendar['days']).to contain_exactly(
        { 'date' => (pushed_at.to_date + 1.day).iso8601, 'count' => 1 }
      )
    end
  end

  context 'when the target user profile is readable' do
    let_it_be(:current_user) { create(:user) }

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    it_behaves_like 'the calendar of the target user'
  end

  context 'when the target user has not set a timezone' do
    let_it_be(:current_user) { create(:user) }

    before do
      target_user.user_preference.update!(timezone: nil)
    end

    it 'falls back to the timezone of the instance' do
      expect(calendar).to include('utcOffset' => 0, 'timezone' => 'Etc/UTC')
    end

    it 'counts the contributions on the days of the timezone of the instance' do
      expect(calendar['days']).to contain_exactly({ 'date' => pushed_at.to_date.iso8601, 'count' => 1 })
    end
  end

  context 'when the target user profile is private' do
    before do
      target_user.update!(private_profile: true)
    end

    context 'when the viewer is another user' do
      let_it_be(:current_user) { create(:user) }

      it 'returns no calendar' do
        expect(calendar).to be_nil
      end
    end

    context 'when the viewer is the target user' do
      let(:current_user) { target_user }

      it_behaves_like 'the calendar of the target user'
    end
  end
end
