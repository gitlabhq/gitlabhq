# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberSerializer do
  include MembersPresentation

  let_it_be(:current_user) { create(:user) }

  subject(:representation) do
    described_class.new.represent(members, { current_user: current_user, group: group, source: source }).to_json
  end

  shared_examples 'members.json' do
    it { is_expected.to match_schema('members') }
  end

  context 'group member' do
    let_it_be(:group) { create(:group) }
    let_it_be(:members) { present_members(create_list(:group_member, 1, group: group)) }

    let(:source) { group }

    it_behaves_like 'members.json'

    it 'handles last group owner assignment' do
      group_member = members.last

      expect { representation }.to change(group_member, :last_owner)
                                     .from(nil).to(true)
                                     .and change(group_member, :last_blocked_owner).from(nil).to(false)
    end

    context "with LastGroupOwnerAssigner query improvements" do
      it "avoids N+1 database queries for last group owner assignment in MembersPresenter" do
        group_member = create(:group_member, group: group)
        control_count = ActiveRecord::QueryRecorder.new { member_last_owner_with_preload([group_member]) }.count
        group_members = create_list(:group_member, 3, group: group)

        expect { member_last_owner_with_preload(group_members) }.not_to exceed_query_limit(control_count)
      end

      it "avoids N+1 database queries for last blocked owner assignment in MembersPresenter" do
        group_member = create(:group_member, group: group)
        control_count = ActiveRecord::QueryRecorder.new { member_last_blocked_owner_with_preload([group_member]) }.count
        group_members = create_list(:group_member, 3, group: group)

        expect { member_last_blocked_owner_with_preload(group_members) }.not_to exceed_query_limit(control_count)
      end

      def member_last_owner_with_preload(members)
        assigner_with_preload(members)
        members.map { |m| group.member_last_owner?(m) }
      end

      def member_last_blocked_owner_with_preload(members)
        assigner_with_preload(members)
        members.map { |m| group.member_last_blocked_owner?(m) }
      end

      def assigner_with_preload(members)
        MembersPreloader.new(members).preload_all
        Members::LastGroupOwnerAssigner.new(group, members).execute
      end
    end
  end

  context 'project member' do
    let_it_be(:project) { create(:project) }
    let_it_be(:members) { present_members(create_list(:project_member, 1, project: project)) }

    let(:source) { project }
    let(:group) { project.group }

    it_behaves_like 'members.json'

    it 'does not invoke group owner assignment' do
      expect(Members::LastGroupOwnerAssigner).not_to receive(:new)

      representation
    end
  end
end
