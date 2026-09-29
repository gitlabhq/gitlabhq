# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::GroupAssociationDetails, feature_category: :system_access do
  subject(:entity) { described_class.new(group, options) }

  let_it_be(:parent_group) { create(:group) }
  let_it_be(:group) { create(:group, parent: parent_group) }
  let_it_be(:user) { create(:user) }

  let(:options) { { current_user: user } }

  describe '#as_json' do
    subject(:as_json) { entity.as_json }

    context 'when current_user has no membership in the group' do
      it 'includes group association fields with a nil access_levels' do
        is_expected.to eq(
          id: group.id,
          name: group.name,
          web_url: group.web_url,
          parent_id: group.parent_id,
          organization_id: group.organization_id,
          access_levels: nil,
          visibility: group.visibility
        )
      end
    end

    context 'when current_user is a member of the group' do
      before_all do
        group.add_maintainer(user)
      end

      it 'includes the highest access level' do
        expect(as_json[:access_levels]).to eq(Gitlab::Access::MAINTAINER)
      end
    end
  end
end
