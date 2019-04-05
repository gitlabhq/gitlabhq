require 'spec_helper'

describe Projects::ParticipantsService do
  describe '#groups' do
    set(:user) { create(:user) }
    set(:project) { create(:project, :public) }
    let(:service) { described_class.new(project, user) }

    it 'avoids N+1 queries' do
      group_1 = create(:group)
      group_1.add_owner(user)

      service.groups # Run general application warmup queries
      control_count = ActiveRecord::QueryRecorder.new { service.groups }.count

      group_2 = create(:group)
      group_2.add_owner(user)

      expect { service.groups }.not_to exceed_query_limit(control_count)
    end

    it 'returns correct user counts for groups' do
      group_1 = create(:group)
      group_1.add_owner(user)
      group_1.add_owner(create(:user))

      group_2 = create(:group)
      group_2.add_owner(user)
      create(:group_member, :access_request, group: group_2, user: create(:user))

      expect(service.groups).to contain_exactly(
        a_hash_including(name: group_1.full_name, count: 2),
        a_hash_including(name: group_2.full_name, count: 1)
      )
    end

    describe 'avatar_url' do
      let(:group) { create(:group, avatar: fixture_file_upload('spec/fixtures/dk.png')) }

      before do
        group.add_owner(user)
      end

      it 'returns an url for the avatar' do
        expect(service.groups.size).to eq 1
        expect(service.groups.first[:avatar_url]).to eq("/uploads/-/system/group/avatar/#{group.id}/dk.png")
      end

      it 'returns an url for the avatar with relative url' do
        stub_config_setting(relative_url_root: '/gitlab')
        stub_config_setting(url: Settings.send(:build_gitlab_url))

        expect(service.groups.size).to eq 1
        expect(service.groups.first[:avatar_url]).to eq("/gitlab/uploads/-/system/group/avatar/#{group.id}/dk.png")
      end
    end
  end
end
