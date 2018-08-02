require 'spec_helper'

describe Todos::Destroy::GroupPrivateService do
  let(:group)        { create(:group, :public) }
  let(:user)         { create(:user) }
  let(:group_member) { create(:user) }

  let!(:todo_non_member)         { create(:todo, user: user, group: group) }
  let!(:todo_member)             { create(:todo, user: group_member, group: group) }
  let!(:todo_another_non_member) { create(:todo, user: user, group: group) }

  describe '#execute' do
    before do
      group.add_developer(group_member)
    end

    subject { described_class.new(group.id).execute }

    context 'when a group set to private' do
      before do
        group.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'removes todos for a user who is not a member' do
        expect { subject }.to change { Todo.count }.from(3).to(1)

        expect(user.todos).to be_empty
        expect(group_member.todos).to match_array([todo_member])
      end
    end

    context 'when group is not private' do
      it 'does not remove any todos' do
        expect { subject }.not_to change { Todo.count }
      end
    end
  end
end
