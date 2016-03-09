require 'spec_helper'

describe Groups::UpdateService, services: true do
    let!(:user)    { create(:user) }
    let!(:private_group)    { create(:group, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }
    let!(:internal_group)   { create(:group, visibility_level: Gitlab::VisibilityLevel::INTERNAL) }
    let!(:public_group)     { create(:group, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }

  describe "execute" do
    context "project visibility_level validation" do

      context "public group with public projects" do
        let!(:service) { described_class.new(public_group, user, visibility_level: Gitlab::VisibilityLevel::INTERNAL ) }

        before do
          public_group.add_user(user, Gitlab::Access::MASTER)
          create(:project, :public, group: public_group, name: 'B', path: 'B')
        end

        it "cant downgrade permission level" do
          expect(service.execute).to be_falsy
          expect(public_group.errors.count).to eq(1)
        end
      end

    context "internal group with internal project" do
        let!(:service) { described_class.new(internal_group, user, visibility_level: Gitlab::VisibilityLevel::PRIVATE ) }

        before do
          internal_group.add_user(user, Gitlab::Access::MASTER)
          create(:project, :internal, group: internal_group, name: 'B', path: 'B')
        end

        it "cant downgrade permission level" do
          expect(service.execute).to be_falsy
          expect(internal_group.errors.count).to eq(1)
        end
      end
    end
  end

  context "unauthorized visibility_level validation" do
    let!(:service) { described_class.new(internal_group, user, visibility_level: 99 ) }
    before { internal_group.add_user(user, Gitlab::Access::MASTER) }

    it "does not change permission level" do
      expect(service.execute).to be_falsy
      expect(internal_group.errors.count).to eq(1)
    end
  end
end
