RSpec.shared_examples 'members and requesters associations' do
  describe '#members_and_requesters' do
    it 'includes members and requesters' do
      member_and_requester_user_ids = namespace.members_and_requesters.pluck(:user_id)

      expect(member_and_requester_user_ids).to include(requester.id, developer.id)
    end
  end

  describe '#members' do
    it 'includes members and exclude requesters' do
      member_user_ids = namespace.members.pluck(:user_id)

      expect(member_user_ids).to include(developer.id)
      expect(member_user_ids).not_to include(requester.id)
    end
  end

  describe '#requesters' do
    it 'does not include requesters' do
      requester_user_ids = namespace.requesters.pluck(:user_id)

      expect(requester_user_ids).to include(requester.id)
      expect(requester_user_ids).not_to include(developer.id)
    end
  end
end
