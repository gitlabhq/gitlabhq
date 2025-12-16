# frozen_string_literal: true

RSpec.shared_examples 'roles_user_can_assign' do
  include RolesHelpers

  subject(:roles_user_can_assign) { resource.roles_user_can_assign(user, roles) }

  let_it_be(:user) { create(:user) }
  let(:roles) { nil }

  context 'when user is not a member' do
    let(:non_member_user) { create(:user) }

    specify { expect(resource.roles_user_can_assign(non_member_user)).to eq({}) }
  end

  context 'when role hash is passed in' do
    let(:roles) { Gitlab::Access.options_with_none }

    before do
      membership.update!(access_level: access_level_value(:guest))
    end

    it "includes the passed in roles encompassed by the user's max access level" do
      expect(roles_user_can_assign.keys).to match_array(%w[Guest None])
    end
  end

  RolesHelpers.assignable_roles.each do |current_level, expected|
    context "when user is #{current_level}" do
      let(:expected_levels) { expected.map { |role| access_level_value(role) } }

      before do
        membership.update!(access_level: access_level_value(current_level))
      end

      specify { expect(roles_user_can_assign.values).to match_array(expected_levels) }
    end
  end
end

RSpec.shared_examples 'a resource that has roles' do |resource_type|
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:resource) { create(resource_type) } # rubocop: disable Rails/SaveBang -- there is no create! method in FactoryBot

  before_all do
    resource.add_member(user, :reporter)
  end

  describe '#can_assign_role?' do
    subject(:can_assign_role) { resource.can_assign_role?(user, access_level) }

    context 'when the access_level is nil' do
      let(:access_level) { nil }

      it { is_expected.to be(true) }
    end

    context "when the current user's role encompasses the role being assigned" do
      let(:access_level) { Gitlab::Access::GUEST }

      it { is_expected.to be(true) }
    end

    context "when the current user's role does not encompass the role being assigned" do
      let(:access_level) { Gitlab::Access::MAINTAINER }

      it { is_expected.to be(false) }

      context 'when the current user is admin', :enable_admin_mode do
        subject(:can_assign_role) { resource.can_assign_role?(admin, access_level) }

        it { is_expected.to be(true) }
      end
    end
  end
end
