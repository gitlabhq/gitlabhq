# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LastGroupOwnerAssigner do
  describe "#execute" do
    let_it_be(:user, reload: true) { create(:user) }
    let_it_be(:group) { create(:group) }

    let(:group_member) { user.members.last }

    subject(:assigner) { described_class.new(group, [group_member]) }

    before do
      group.add_owner(user)
    end

    it "avoids extra database queries utilizing memoization", :aggregate_failures do
      control = ActiveRecord::QueryRecorder.new { assigner.execute }
      count_queries = control.occurrences_by_line_method.first[1][:occurrences].find_all { |i| i.include?('SELECT COUNT') }

      expect(control.count).to be <= 5
      expect(count_queries.count).to eq(0)
    end

    context "when there are unblocked owners" do
      context "with one unblocked owner" do
        specify do
          expect { assigner.execute }.to change(group_member, :last_owner)
                                           .from(nil).to(true)
                                           .and change(group_member, :last_blocked_owner)
                                                  .from(nil).to(false)
        end
      end

      context "with multiple unblocked owners" do
        let_it_be(:unblocked_owner_member) { create(:group_member, :owner, source: group) }

        specify do
          expect { assigner.execute }.to change(group_member, :last_owner)
                                           .from(nil).to(false)
                                           .and change(group_member, :last_blocked_owner)
                                                  .from(nil).to(false)
        end

        it "has many members passed" do
          assigner = described_class.new(group, [unblocked_owner_member, group_member])

          expect { assigner.execute }.to change(group_member, :last_owner)
                                           .from(nil).to(false)
                                           .and change(group_member, :last_blocked_owner)
                                                  .from(nil).to(false)
                                                  .and change(unblocked_owner_member, :last_owner)
                                                         .from(nil).to(false)
                                                         .and change(unblocked_owner_member, :last_blocked_owner)
                                                                .from(nil).to(false)
        end
      end
    end

    context "when there are blocked owners" do
      before do
        user.block!
      end

      context "with one blocked owner" do
        specify do
          expect { assigner.execute }.to change(group_member, :last_owner)
                                           .from(nil).to(false)
                                           .and change(group_member, :last_blocked_owner)
                                                  .from(nil).to(true)
        end
      end

      context "with multiple unblocked owners" do
        specify do
          create_list(:group_member, 2, :owner, source: group)

          expect { assigner.execute }.to change(group_member, :last_owner)
                                           .from(nil).to(false)
                                           .and change(group_member, :last_blocked_owner)
                                                  .from(nil).to(false)
        end
      end

      context "with multiple blocked owners" do
        specify do
          create(:group_member, :owner, :blocked, source: group)

          expect { assigner.execute }.to change(group_member, :last_owner)
                                           .from(nil).to(false)
                                           .and change(group_member, :last_blocked_owner)
                                                  .from(nil).to(false)
        end
      end
    end
  end
end
