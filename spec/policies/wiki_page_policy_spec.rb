# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiPagePolicy, feature_category: :wiki do
  include_context 'ProjectPolicyTable context'
  include ProjectHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group, :public) }
  let_it_be_with_refind(:public_project) { create(:project, :public, group: group) }
  let_it_be_with_refind(:internal_project) { create(:project, :internal, group: group) }
  let_it_be_with_refind(:private_project) { create(:project, :private, group: group) }

  let_it_be(:admin) { create(:admin) }
  let_it_be(:non_member) { create(:user) }
  let_it_be(:project_developer) { create(:user, developer_of: [public_project, internal_project, private_project]) }
  let_it_be(:project_reporter) { create(:user, reporter_of: [public_project, internal_project, private_project]) }
  let_it_be(:project_guest) { create(:user, guest_of: [public_project, internal_project, private_project]) }
  let_it_be(:group_reporter) { create(:user, reporter_of: group) }
  let_it_be(:group_guest) { create(:user, guest_of: group) }

  let(:project) { public_send(:"#{project_level}_project") }
  let(:wiki_page) { build(:wiki_page, container: project) }
  let(:project_level) { :public }

  def user_for(source, membership)
    case membership
    when :anonymous then nil
    when :non_member then non_member
    when :admin then admin
    else public_send(:"#{source}_#{membership}")
    end
  end

  subject(:policy) { described_class.new(user, wiki_page) }

  shared_examples 'with :read_wiki_page policy' do
    where(:project_level, :feature_access_level, :membership, :admin_mode, :expected_count) do
      permission_table_for_notes_feature_access
    end

    with_them do
      it 'grants the expected permissions', :aggregate_failures do
        enable_admin_mode!(user) if admin_mode
        update_feature_access_level(project, feature_access_level)

        if expected_count == 2
          expect(policy).to be_allowed(:mark_note_as_internal)
          expect(policy).to be_allowed(:read_wiki_page)
          expect(policy).to be_allowed(:read_note)
          expect(policy).to be_allowed(:create_note)
          expect(policy).to be_allowed(:update_subscription)
          expect(policy).to be_allowed(:award_emoji)
        elsif expected_count == 1
          expect(policy).to be_disallowed(:mark_note_as_internal)
          expect(policy).to be_allowed(:read_wiki_page)
          expect(policy).to be_allowed(:read_note)
          expect(policy).to be_allowed(:create_note)
          expect(policy).to be_allowed(:update_subscription)
          expect(policy).to be_allowed(:award_emoji)
        else
          expect(policy).to be_disallowed(:mark_note_as_internal)
          expect(policy).to be_disallowed(:read_wiki_page)
          expect(policy).to be_disallowed(:read_note)
          expect(policy).to be_disallowed(:create_note)
          expect(policy).to be_disallowed(:update_subscription)
          expect(policy).to be_disallowed(:award_emoji)
        end
      end
    end
  end

  context 'when user is a direct project member' do
    let(:user) { user_for(:project, membership) }

    include_context 'with :read_wiki_page policy'
  end

  context 'when user is an inherited member from the group' do
    let(:user) { user_for(:group, membership) }

    include_context 'with :read_wiki_page policy'
  end

  context 'when user is a developer' do
    let(:user) { project_developer }

    it 'grants the resolve_note permission' do
      expect(policy).to be_allowed(:resolve_note)
    end
  end

  context 'when user is not a developer' do
    where(:membership) do
      %i[reporter guest non_member anonymous]
    end

    with_them do
      let(:user) { user_for(:project, membership) }

      it 'does not grant the resolve_note permission' do
        expect(policy).to be_disallowed(:resolve_note)
      end
    end
  end
end
