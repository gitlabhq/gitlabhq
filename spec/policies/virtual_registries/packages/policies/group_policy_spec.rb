# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VirtualRegistries::Packages::Policies::GroupPolicy, feature_category: :virtual_registry do
  include_context 'GroupPolicy context'
  using RSpec::Parameterized::TableSyntax

  let_it_be(:subgroup) { create(:group, parent: group, visibility_level: group.visibility_level) }
  let(:policy_subject) { ::VirtualRegistries::Packages::Policies::Group.new(group) }

  subject { described_class.new(current_user, policy_subject) }

  describe 'read_virtual_registry' do
    where(:group_visibility, :current_user, :allowed?) do
      'PUBLIC' | nil                    | false
      'PUBLIC' | ref(:non_group_member) | true
      'PUBLIC' | ref(:guest)            | true
      'PUBLIC' | ref(:reporter)         | true
      'PUBLIC' | ref(:developer)        | true
      'PUBLIC' | ref(:maintainer)       | true
      'PUBLIC' | ref(:owner)            | true

      'INTERNAL' | nil                    | false
      'INTERNAL' | ref(:non_group_member) | true
      'INTERNAL' | ref(:guest)            | true
      'INTERNAL' | ref(:reporter)         | true
      'INTERNAL' | ref(:developer)        | true
      'INTERNAL' | ref(:maintainer)       | true
      'INTERNAL' | ref(:owner)            | true

      'PRIVATE' | nil                    | false
      'PRIVATE' | ref(:non_group_member) | false
      'PRIVATE' | ref(:guest)            | true
      'PRIVATE' | ref(:reporter)         | true
      'PRIVATE' | ref(:developer)        | true
      'PRIVATE' | ref(:maintainer)       | true
      'PRIVATE' | ref(:owner)            | true
    end

    with_them do
      before do
        group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_visibility, false))
      end

      it { is_expected.to public_send(allowed? ? :be_allowed : :be_disallowed, :read_virtual_registry) }
    end

    context 'for deploy token' do
      let(:deploy_token) do
        create(:deploy_token, :group).tap do |token|
          create(:group_deploy_token, group: target, deploy_token: token)
        end
      end

      subject { described_class.new(deploy_token, policy_subject) }

      where(:target, :group_visibility, :read_virtual_registry, :allowed?) do
        ref(:group) | 'PUBLIC'   | true  | true
        ref(:group) | 'PUBLIC'   | false | false
        ref(:group) | 'INTERNAL' | true  | true
        ref(:group) | 'INTERNAL' | false | false
        ref(:group) | 'PRIVATE'  | true  | true
        ref(:group) | 'PRIVATE'  | false | false

        ref(:subgroup) | 'PUBLIC'   | true  | false
        ref(:subgroup) | 'PUBLIC'   | false | false
        ref(:subgroup) | 'INTERNAL' | true  | false
        ref(:subgroup) | 'INTERNAL' | false | false
        ref(:subgroup) | 'PRIVATE'  | true  | false
        ref(:subgroup) | 'PRIVATE'  | false | false
      end

      with_them do
        before do
          deploy_token.read_virtual_registry = read_virtual_registry
          group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_visibility, false))
        end

        it { is_expected.to public_send(allowed? ? :be_allowed : :be_disallowed, :read_virtual_registry) }
      end
    end
  end

  %i[create update destroy].each do |action|
    describe "#{action}_virtual_registry" do
      where(:group_visibility, :current_user, :allowed?) do
        'PUBLIC' | nil                    | false
        'PUBLIC' | ref(:non_group_member) | false
        'PUBLIC' | ref(:guest)            | false
        'PUBLIC' | ref(:reporter)         | false
        'PUBLIC' | ref(:developer)        | false
        'PUBLIC' | ref(:maintainer)       | true
        'PUBLIC' | ref(:owner)            | true

        'INTERNAL' | nil                    | false
        'INTERNAL' | ref(:non_group_member) | false
        'INTERNAL' | ref(:guest)            | false
        'INTERNAL' | ref(:reporter)         | false
        'INTERNAL' | ref(:developer)        | false
        'INTERNAL' | ref(:maintainer)       | true
        'INTERNAL' | ref(:owner)            | true

        'PRIVATE' | nil                    | false
        'PRIVATE' | ref(:non_group_member) | false
        'PRIVATE' | ref(:guest)            | false
        'PRIVATE' | ref(:reporter)         | false
        'PRIVATE' | ref(:developer)        | false
        'PRIVATE' | ref(:maintainer)       | true
        'PRIVATE' | ref(:owner)            | true
      end

      with_them do
        before do
          group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_visibility, false))
        end

        it { is_expected.to public_send(allowed? ? :be_allowed : :be_disallowed, :"#{action}_virtual_registry") }
      end
    end
  end
end
