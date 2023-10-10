# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LastGroupOwnerAssigner, feature_category: :groups_and_projects do
  describe "#execute" do
    let_it_be(:user, reload: true) { create(:user) }
    let_it_be(:group) { create(:group) }

    let!(:group_member) { group.add_owner(user) }

    subject(:assigner) { described_class.new(group, [group_member]) }

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
        end
      end

      context "with multiple unblocked owners" do
        let_it_be(:unblocked_owner_member) { create(:group_member, :owner, source: group) }

        specify do
          expect { assigner.execute }.to change(group_member, :last_owner)
                                           .from(nil).to(false)
        end

        it "has many members passed" do
          assigner = described_class.new(group, [unblocked_owner_member, group_member])

          expect { assigner.execute }.to change(group_member, :last_owner)
                                           .from(nil).to(false)
                                                  .and change(unblocked_owner_member, :last_owner)
                                                         .from(nil).to(false)
        end
      end

      context 'with owners from a parent' do
        context 'when top-level group' do
          context 'with group sharing' do
            let!(:subgroup) { create(:group, parent: group) }

            before do
              create(:group_group_link, :owner, shared_group: group, shared_with_group: subgroup)
              create(:group_member, :owner, group: subgroup)
            end

            specify do
              expect { assigner.execute }.to change(group_member, :last_owner)
                .from(nil).to(true)
            end
          end
        end

        context 'when subgroup' do
          let!(:subgroup) { create(:group, parent: group) }
          let!(:group_member_2) { subgroup.add_owner(user) }

          subject(:assigner) { described_class.new(subgroup, [group_member_2]) }

          specify do
            expect { assigner.execute }.to change(group_member_2, :last_owner)
              .from(nil).to(false)
          end
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
                                           .from(nil).to(true)
        end
      end

      context "with multiple unblocked owners" do
        specify do
          create_list(:group_member, 2, :owner, source: group)

          expect { assigner.execute }.to change(group_member, :last_owner)
                                           .from(nil).to(false)
        end
      end

      context "with multiple blocked owners" do
        specify do
          create(:group_member, :owner, :blocked, source: group)

          expect { assigner.execute }.to change(group_member, :last_owner)
                                           .from(nil).to(false)
        end
      end

      context 'with owners from a parent' do
        context 'when top-level group' do
          context 'with group sharing' do
            let!(:subgroup) { create(:group, parent: group) }

            before do
              create(:group_group_link, :owner, shared_group: group, shared_with_group: subgroup)
              create(:group_member, :owner, group: subgroup)
            end

            specify do
              expect { assigner.execute }.to change(group_member, :last_owner)
                .from(nil).to(true)
            end
          end
        end

        context 'when subgroup' do
          let!(:subgroup) { create(:group, :nested) }

          let!(:group_member) { subgroup.add_owner(user) }

          subject(:assigner) { described_class.new(subgroup, [group_member]) }

          specify do
            expect { assigner.execute }.to change(group_member, :last_owner)
              .from(nil).to(true)
          end

          context 'with two owners' do
            before do
              create(:group_member, :owner, group: subgroup.parent)
            end

            specify do
              expect { assigner.execute }.to change(group_member, :last_owner)
                .from(nil).to(false)
            end
          end
        end
      end
    end

    context 'when there are bot members' do
      context 'with a bot owner' do
        specify do
          create(:group_member, :owner, source: group, user: create(:user, :project_bot))

          expect { assigner.execute }.to change(group_member, :last_owner)
            .from(nil).to(true)
        end
      end
    end
  end
end
