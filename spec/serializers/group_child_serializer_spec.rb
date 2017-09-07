require 'spec_helper'

describe GroupChildSerializer do
  let(:request) { double('request') }
  let(:user) { create(:user) }
  subject(:serializer) { described_class.new(current_user: user) }

  describe '#represent' do
    context 'for groups' do
      it 'can render a single group' do
        expect(serializer.represent(build(:group))).to be_kind_of(Hash)
      end

      it 'can render a collection of groups' do
        expect(serializer.represent(build_list(:group, 2))).to be_kind_of(Array)
      end
    end

    context 'with a hierarchy' do
      let(:parent) { create(:group) }

      subject(:serializer) do
        described_class.new(current_user: user).expand_hierarchy(parent)
      end

      it 'expands the subgroups' do
        subgroup = create(:group, parent: parent)
        subsub_group = create(:group, parent: subgroup)

        json = serializer.represent(subsub_group)
        subsub_group_json = json[:children].first

        expect(json[:id]).to eq(subgroup.id)
        expect(subsub_group_json).not_to be_nil
        expect(subsub_group_json[:id]).to eq(subsub_group.id)
      end

      it 'can expand multiple trees' do

      end
    end
  end
end
