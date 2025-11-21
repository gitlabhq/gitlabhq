# frozen_string_literal: true

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

      it 'returns true' do
        expect(can_assign_role).to be(true)
      end
    end

    context "when the current user's role encompasses the role being assigned" do
      let(:access_level) { Gitlab::Access::GUEST }

      it { is_expected.to be(true) }
    end

    context "when the current user's role does not encompass the role being assigned" do
      let(:access_level) { Gitlab::Access::MAINTAINER }

      it 'returns false' do
        expect(can_assign_role).to be(false)
      end

      context 'when the current user is admin', :enable_admin_mode do
        subject(:can_assign_role) { resource.can_assign_role?(admin, access_level) }

        it 'returns true' do
          expect(can_assign_role).to be(true)
        end
      end
    end
  end
end
