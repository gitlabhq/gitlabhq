# frozen_string_literal: true

shared_examples_for 'inherited access level as a member of entity' do
  let(:parent_entity) { create(:group) }
  let(:user) { create(:user) }
  let(:member) { entity.is_a?(Group) ? entity.group_member(user) : entity.project_member(user) }

  context 'with root parent_entity developer member' do
    before do
      parent_entity.add_developer(user)
    end

    it 'is allowed to be a maintainer of the entity' do
      entity.add_maintainer(user)

      expect(member.access_level).to eq(Gitlab::Access::MAINTAINER)
    end

    it 'is not allowed to be a reporter of the entity' do
      entity.add_reporter(user)

      expect(member).to be_nil
    end

    it 'is allowed to change to be a developer of the entity' do
      entity.add_maintainer(user)

      expect { member.update(access_level: Gitlab::Access::DEVELOPER) }
        .to change { member.access_level }.to(Gitlab::Access::DEVELOPER)
    end

    it 'is not allowed to change to be a guest of the entity' do
      entity.add_maintainer(user)

      expect { member.update(access_level: Gitlab::Access::GUEST) }
        .not_to change { member.reload.access_level }
    end

    it "shows an error if the member can't be updated" do
      entity.add_maintainer(user)

      member.update(access_level: Gitlab::Access::REPORTER)

      expect(member.errors.full_messages).to eq(["Access level should be greater than or equal to Developer inherited membership from group #{parent_entity.name}"])
    end

    it 'allows changing the level from a non existing member' do
      non_member_user = create(:user)

      entity.add_maintainer(non_member_user)

      non_member = entity.is_a?(Group) ? entity.group_member(non_member_user) : entity.project_member(non_member_user)

      expect { non_member.update(access_level: Gitlab::Access::GUEST) }
        .to change { non_member.reload.access_level }
    end
  end
end

shared_examples_for '#valid_level_roles' do |entity_name|
  let(:member_user) { create(:user) }
  let(:group) { create(:group) }
  let(:entity) { create(entity_name) }
  let(:entity_member) { create("#{entity_name}_member", :developer, source: entity, user: member_user) }
  let(:presenter) { described_class.new(entity_member, current_user: member_user) }
  let(:expected_roles) { { 'Developer' => 30, 'Maintainer' => 40, 'Reporter' => 20 } }

  it 'returns all roles when no parent member is present' do
    expect(presenter.valid_level_roles).to eq(entity_member.class.access_level_roles)
  end

  it 'returns higher roles when a parent member is present' do
    group.add_reporter(member_user)

    expect(presenter.valid_level_roles).to eq(expected_roles)
  end
end
