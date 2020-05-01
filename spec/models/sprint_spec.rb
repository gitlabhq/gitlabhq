# frozen_string_literal: true

require 'spec_helper'

describe Sprint do
  it_behaves_like 'a timebox', :sprint

  describe "#iid" do
    let!(:project) { create(:project) }
    let!(:group) { create(:group) }

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
