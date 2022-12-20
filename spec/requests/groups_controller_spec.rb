# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupsController, feature_category: :subgroups do
  context 'token authentication' do
    context 'when public group' do
      let_it_be(:public_group) { create(:group, :public) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'show atom', public_resource: true do
        let(:url) { group_path(public_group, format: :atom) }
      end

      it_behaves_like 'authenticates sessionless user for the request spec', 'issues atom', public_resource: true do
        let(:url) { issues_group_path(public_group, format: :atom) }
      end

      it_behaves_like 'authenticates sessionless user for the request spec', 'issues_calendar ics', public_resource: true do
        let(:url) { issues_group_calendar_url(public_group, format: :ics) }
      end
    end

    context 'when private project' do
      let_it_be(:private_group) { create(:group, :private) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'show atom', public_resource: false, ignore_metrics: true do
        let(:url) { group_path(private_group, format: :atom) }

        before do
          private_group.add_maintainer(user)
        end
      end

      it_behaves_like 'authenticates sessionless user for the request spec', 'issues atom', public_resource: false, ignore_metrics: true do
        let(:url) { issues_group_path(private_group, format: :atom) }

        before do
          private_group.add_maintainer(user)
        end
      end

      it_behaves_like 'authenticates sessionless user for the request spec', 'issues_calendar ics', public_resource: false, ignore_metrics: true do
        let(:url) { issues_group_calendar_url(private_group, format: :ics) }

        before do
          private_group.add_maintainer(user)
        end
      end
    end
  end
end
