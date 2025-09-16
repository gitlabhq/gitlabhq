# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work Items', feature_category: :team_planning do
  let_it_be(:work_item) { create(:work_item) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }

  describe 'GET /:namespace/-/work_items.ics' do
    let(:work_items_path) { group_work_items_url(group, format: :ics) }

    context 'when using token access' do
      context 'on public groups' do
        let(:public_group) { create(:group, :public) }

        it_behaves_like 'authenticates sessionless user for the request spec', 'calendar ics', public_resource: true do
          let(:url) { group_work_items_url(public_group, format: :ics) }

          before do
            public_group.add_maintainer(user)
          end
        end
      end

      context 'on private groups' do
        let(:private_group) { create(:group, :private) }

        it_behaves_like 'authenticates sessionless user for the request spec',
          'calendar ics',
          public_resource: false,
          ignore_metrics: true do
          let(:url) { group_work_items_url(private_group, format: :ics) }

          before do
            private_group.add_maintainer(user)
          end
        end
      end
    end

    context 'when the user can read the group' do
      before do
        sign_in(current_user)
      end

      it 'renders calendar' do
        get work_items_path

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Content-Type']).to have_content('text/calendar')
        expect(response.body).to have_text('BEGIN:VCALENDAR')
      end
    end

    context 'when the user cannot read the group' do
      before do
        sign_in(current_user)
      end

      let(:private_group) { create(:group, :private) }

      it 'returns not found' do
        get group_work_items_url(private_group, format: :ics)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
