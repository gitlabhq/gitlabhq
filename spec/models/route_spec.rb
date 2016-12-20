require 'spec_helper'

describe Route, models: true do
  let!(:group) { create(:group, path: 'gitlab') }
  let!(:route) { group.route }

  describe 'relationships' do
    it { is_expected.to belong_to(:source) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_uniqueness_of(:path) }
  end

  describe '#rename_children' do
    let!(:nested_group) { create(:group, path: "test", parent: group) }
    let!(:deep_nested_group) { create(:group, path: "foo", parent: nested_group) }
    let!(:similar_group) { create(:group, path: 'gitlab-org') }

    before { route.update_attributes(path: 'bar') }

    it "updates children routes with new path" do
      expect(described_class.exists?(path: 'bar')).to be_truthy
      expect(described_class.exists?(path: 'bar/test')).to be_truthy
      expect(described_class.exists?(path: 'bar/test/foo')).to be_truthy
      expect(described_class.exists?(path: 'gitlab-org')).to be_truthy
    end
  end
end
