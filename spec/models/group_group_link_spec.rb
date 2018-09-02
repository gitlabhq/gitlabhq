require 'spec_helper'

describe GroupGroupLink do
  describe 'validation' do
    let(:group) { create(:group) }
    let(:shared_group) { create(:group) }
    let!(:group_group_link) { create(:group_group_link, shared_group: shared_group, shared_with_group: group) }

    it { is_expected.to validate_presence_of(:shared_group) }
    it { is_expected.to validate_uniqueness_of(:shared_group_id).scoped_to(:shared_with_group_id).with_message(/already shared/) }
    it { is_expected.to validate_presence_of(:shared_group) }
    it { is_expected.to validate_presence_of(:group_access) }
    it { is_expected.to validate_inclusion_of(:group_access).in_array(Gitlab::Access.values) }

    # it 'does not allow a project to be shared with the group it is in' do
    #   project_group_link.group = group
    #
    #   expect(project_group_link).not_to be_valid
    # end
    #
    # it 'doesn not allow a project to be shared with an ancestor of the group it is in', :nested_groups do
    #   project_group_link.group = parent_group
    #
    #   expect(project_group_link).not_to be_valid
    # end
  end
end
