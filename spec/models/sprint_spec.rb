# frozen_string_literal: true

require 'spec_helper'

describe Sprint do
  let!(:project) { create(:project) }
  let!(:group) { create(:group) }

  describe 'modules' do
    context 'with a project' do
      it_behaves_like 'AtomicInternalId' do
        let(:internal_id_attribute) { :iid }
        let(:instance) { build(:sprint, project: build(:project), group: nil) }
        let(:scope) { :project }
        let(:scope_attrs) { { project: instance.project } }
        let(:usage) {:sprints }
      end
    end

    context 'with a group' do
      it_behaves_like 'AtomicInternalId' do
        let(:internal_id_attribute) { :iid }
        let(:instance) { build(:sprint, project: nil, group: build(:group)) }
        let(:scope) { :group }
        let(:scope_attrs) { { namespace: instance.group } }
        let(:usage) {:sprints }
      end
    end
  end

  describe "Associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to have_many(:issues) }
    it { is_expected.to have_many(:merge_requests) }
  end

  describe "#iid" do
    it "is properly scoped on project and group" do
      sprint1 = create(:sprint, project: project)
      sprint2 = create(:sprint, project: project)
      sprint3 = create(:sprint, group: group)
      sprint4 = create(:sprint, group: group)
      sprint5 = create(:sprint, project: project)

      want = {
          sprint1: 1,
          sprint2: 2,
          sprint3: 1,
          sprint4: 2,
          sprint5: 3
      }
      got = {
          sprint1: sprint1.iid,
          sprint2: sprint2.iid,
          sprint3: sprint3.iid,
          sprint4: sprint4.iid,
          sprint5: sprint5.iid
      }
      expect(got).to eq(want)
    end
  end
end
