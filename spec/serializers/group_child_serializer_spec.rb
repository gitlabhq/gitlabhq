# frozen_string_literal: true

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

        json = serializer.represent([subgroup, subsub_group]).first
        subsub_group_json = json[:children].first

        expect(json[:id]).to eq(subgroup.id)
        expect(subsub_group_json).not_to be_nil
        expect(subsub_group_json[:id]).to eq(subsub_group.id)
      end

      it 'can render a nested tree' do
        subgroup1 = create(:group, parent: parent)
        subsub_group1 = create(:group, parent: subgroup1)
        subgroup2 = create(:group, parent: parent)

        json = serializer.represent([subgroup1, subsub_group1, subgroup1, subgroup2])
        subgroup1_json = json.first
        subsub_group1_json = subgroup1_json[:children].first

        expect(json.size).to eq(2)
        expect(subgroup1_json[:id]).to eq(subgroup1.id)
        expect(subsub_group1_json[:id]).to eq(subsub_group1.id)
      end

      context 'without a specified parent' do
        subject(:serializer) do
          described_class.new(current_user: user).expand_hierarchy
        end

        it 'can render a tree' do
          subgroup = create(:group, parent: parent)

          json = serializer.represent([parent, subgroup])
          parent_json = json.first

          expect(parent_json[:id]).to eq(parent.id)
          expect(parent_json[:children].first[:id]).to eq(subgroup.id)
        end
      end
    end

    context 'for projects' do
      it 'can render a single project' do
        expect(serializer.represent(build(:project))).to be_kind_of(Hash)
      end

      it 'can render a collection of projects' do
        expect(serializer.represent(build_list(:project, 2))).to be_kind_of(Array)
      end

      context 'with a hierarchy' do
        let(:parent) { create(:group) }

        subject(:serializer) do
          described_class.new(current_user: user).expand_hierarchy(parent)
        end

        it 'can render a nested tree' do
          subgroup1 = create(:group, parent: parent)
          project1 = create(:project, namespace: subgroup1)
          subgroup2 = create(:group, parent: parent)
          project2 = create(:project, namespace: subgroup2)

          json = serializer.represent([project1, project2, subgroup1, subgroup2])
          project1_json, project2_json = json.map { |group_json| group_json[:children].first }

          expect(json.size).to eq(2)
          expect(project1_json[:id]).to eq(project1.id)
          expect(project2_json[:id]).to eq(project2.id)
        end

        it 'returns an array when an array of a single instance was given' do
          project = create(:project, namespace: parent)

          json = serializer.represent([project])

          expect(json).to be_kind_of(Array)
          expect(json.size).to eq(1)
        end
      end
    end
  end
end
