# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace::RootStorageStatisticsPolicy do
  using RSpec::Parameterized::TableSyntax

  describe '#rules' do
    let(:statistics) { create(:namespace_root_storage_statistics, namespace: namespace) }
    let(:user) { create(:user) }

    subject { Ability.allowed?(user, :read_statistics, statistics) }

    shared_examples 'deny anonymous users' do
      context 'when the users is anonymous' do
        let(:user) { nil }

        it { is_expected.to be_falsey }
      end
    end

    context 'when the namespace is a personal namespace' do
      let(:owner) { create(:user) }
      let(:namespace) { owner.namespace }

      include_examples 'deny anonymous users'

      context 'when the user is not the owner' do
        it { is_expected.to be_falsey }
      end

      context 'when the user is the owner' do
        let(:user) { owner }

        it { is_expected.to be_truthy }
      end
    end

    context 'when the namespace is a group' do
      let(:user)     { create(:user) }
      let(:external) { create(:user, :external) }

      shared_examples 'allows only owners' do |group_type|
        let(:group) { create(:group, visibility_level: Gitlab::VisibilityLevel.level_value(group_type.to_s)) }
        let(:namespace) { group }

        include_examples 'deny anonymous users'

        where(:user_type, :outcome) do
          [
            [:non_member, false],
            [:guest, false],
            [:reporter, false],
            [:developer, false],
            [:maintainer, false],
            [:owner, true]
          ]
        end

        with_them do
          before do
            group.add_member(user, user_type) unless user_type == :non_member
          end

          it { is_expected.to eq(outcome) }

          context 'when the user is external' do
            let(:user) { external }

            it { is_expected.to eq(outcome) }
          end
        end
      end

      include_examples 'allows only owners', :public
      include_examples 'allows only owners', :private
      include_examples 'allows only owners', :internal
    end
  end
end
