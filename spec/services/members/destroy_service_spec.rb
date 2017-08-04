require 'spec_helper'

describe Members::DestroyService do
  let(:user) { create(:user) }
  let(:member_user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:group) { create(:group, :public) }

  shared_examples 'a service raising ActiveRecord::RecordNotFound' do
    it 'raises ActiveRecord::RecordNotFound' do
      expect { described_class.new(source, user, params).execute }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  shared_examples 'a service raising Gitlab::Access::AccessDeniedError' do
    it 'raises Gitlab::Access::AccessDeniedError' do
      expect { described_class.new(source, user, params).execute }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  shared_examples 'a service destroying a member' do
    it 'destroys the member' do
      expect { described_class.new(source, user, params).execute }.to change { source.members.count }.by(-1)
    end
  end

  context 'when no member are found' do
    let(:params) { { user_id: 42 } }

    it_behaves_like 'a service raising ActiveRecord::RecordNotFound' do
      let(:source) { project }
    end

    it_behaves_like 'a service raising ActiveRecord::RecordNotFound' do
      let(:source) { group }
    end
  end

  context 'when a member is found' do
    before do
      project.team << [member_user, :developer]
      group.add_developer(member_user)
    end
    let(:params) { { user_id: member_user.id } }

    context 'when current user cannot destroy the given member' do
      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
        let(:source) { project }
      end

      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
        let(:source) { group }
      end
    end

    context 'when current user can destroy the given member' do
      before do
        project.team << [user, :master]
        group.add_owner(user)
      end

      it_behaves_like 'a service destroying a member' do
        let(:source) { project }
      end

      it_behaves_like 'a service destroying a member' do
        let(:source) { group }
      end

      context 'when given a :id' do
        let(:params) { { id: project.members.find_by!(user_id: user.id).id } }

        it 'destroys the member' do
          expect { described_class.new(project, user, params).execute }
            .to change { project.members.count }.by(-1)
        end
      end
    end
  end
end
