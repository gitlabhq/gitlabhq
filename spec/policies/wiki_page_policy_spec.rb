# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiPagePolicy, feature_category: :wiki do
  include_context 'ProjectPolicyTable context'
  include ProjectHelpers
  include UserHelpers
  using RSpec::Parameterized::TableSyntax

  let(:group) { build(:group, :public) }
  let(:project) { build(:project, :wiki_repo, project_level, group: group) }
  let(:wiki_page) { build(:wiki_page, container: project) }

  shared_context 'with :read_wiki_page policy' do
    subject(:policy) { described_class.new(user, wiki_page) }

    where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
      permission_table_for_guest_feature_access
    end

    with_them do
      it 'grants the expected permissions', :aggregate_failures do
        enable_admin_mode!(user) if admin_mode
        update_feature_access_level(project, feature_access_level)

        if expected_count == 1
          expect(policy).to be_allowed(:read_wiki_page)
          expect(policy).to be_allowed(:read_note)
          expect(policy).to be_allowed(:create_note)
        else
          expect(policy).to be_disallowed(:read_wiki_page)
          expect(policy).to be_disallowed(:read_note)
          expect(policy).to be_disallowed(:create_note)
        end
      end
    end
  end

  context 'when user is a direct project member' do
    let(:user) { build_user_from_membership(project, membership) }

    include_context 'with :read_wiki_page policy'
  end

  context 'when user is an inherited member from the group' do
    let(:user) { build_user_from_membership(group, membership) }

    include_context 'with :read_wiki_page policy'
  end
end
