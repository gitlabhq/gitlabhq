require 'spec_helper'

describe Projects::ParticipantsService do
  describe '#groups' do
    describe 'avatar_url' do
      let(:project) { create(:project, :public) }
      let(:group) { create(:group, avatar: fixture_file_upload(Rails.root + 'spec/fixtures/dk.png')) }
      let(:user) { create(:user) }
      let!(:group_member) { create(:group_member, group: group, user: user) }

      it 'should return an url for the avatar' do
        participants = described_class.new(project, user)
        groups = participants.groups

        expect(groups.size).to eq 1
        expect(groups.first[:avatar_url]).to eq("/uploads/-/system/group/avatar/#{group.id}/dk.png")
      end

      it 'should return an url for the avatar with relative url' do
        stub_config_setting(relative_url_root: '/gitlab')
        stub_config_setting(url: Settings.send(:build_gitlab_url))

        participants = described_class.new(project, user)
        groups = participants.groups

        expect(groups.size).to eq 1
        expect(groups.first[:avatar_url]).to eq("/gitlab/uploads/-/system/group/avatar/#{group.id}/dk.png")
      end
    end
  end
end
