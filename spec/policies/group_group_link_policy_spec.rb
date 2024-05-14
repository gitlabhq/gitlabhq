# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupGroupLinkPolicy, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:group2) { create(:group, :private) }

  let(:group_group_link) do
    create(:group_group_link, shared_group: group, shared_with_group: group2)
  end

  subject(:policy) { described_class.new(user, group_group_link) }

  describe 'read_shared_with_group' do
    context 'when the user is a shared_group member' do
      context 'when the user is not a shared_group owner' do
        before_all do
          group.add_maintainer(user)
        end

        it 'cannot read_shared_with_group' do
          expect(policy).to be_disallowed(:read_shared_with_group)
        end
      end

      context 'when the user is a shared_group owner' do
        before_all do
          group.add_owner(user)
        end

        it 'can read_shared_with_group' do
          expect(policy).to be_allowed(:read_shared_with_group)
        end
      end
    end

    context 'when the user is not a shared_group member' do
      context 'when user is not a shared_with_group member' do
        context 'when the shared_with_group is private' do
          it 'cannot read_shared_with_group' do
            expect(policy).to be_disallowed(:read_shared_with_group)
          end

          context 'when the shared group is public' do
            let_it_be(:group) { create(:group, :public) }

            it 'cannot read_shared_with_group' do
              expect(policy).to be_disallowed(:read_shared_with_group)
            end
          end
        end

        context 'when the shared_with_group is public' do
          let_it_be(:group2) { create(:group, :public) }

          it 'can read_shared_with_group' do
            expect(policy).to be_allowed(:read_shared_with_group)
          end
        end
      end

      context 'when user is a shared_with_group member' do
        before_all do
          group2.add_developer(user)
        end

        it 'can read_shared_with_group' do
          expect(policy).to be_allowed(:read_shared_with_group)
        end
      end
    end
  end
end
