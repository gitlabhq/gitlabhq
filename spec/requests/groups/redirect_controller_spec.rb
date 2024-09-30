# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Groups::RedirectController requests", feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:private_group) { create(:group, :private) }
  let_it_be(:private_group2) { create(:group, :private) }
  let_it_be(:public_group) { create(:group, :public) }
  let_it_be(:user) { create(:user, developer_of: private_group) }

  describe 'GET redirect_from_id' do
    where(:authenticated, :group, :is_found) do
      true  | ref(:private_group)        | true
      false | ref(:private_group)        | false
      true  | ref(:private_group2)       | false
      true  | ref(:public_group)         | true
      false | ref(:public_group)         | true
      true  | build(:group, id: 0)       | false
    end

    with_them do
      before do
        sign_in(user) if authenticated

        get "/-/g/#{group.id}"
      end

      if params[:is_found]
        it 'redirects to the group page' do
          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(group_path(group))
        end
      else
        it 'gives 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
