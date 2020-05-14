# frozen_string_literal: true

require 'spec_helper'

describe Iteration do
  it_behaves_like 'a timebox', :iteration do
    let(:timebox_table_name) { described_class.table_name.to_sym }
  end

  describe "#iid" do
    let!(:project) { create(:project) }
    let!(:group) { create(:group) }

    it "is properly scoped on project and group" do
      iteration1 = create(:iteration, project: project)
      iteration2 = create(:iteration, project: project)
      iteration3 = create(:iteration, group: group)
      iteration4 = create(:iteration, group: group)
      iteration5 = create(:iteration, project: project)

      want = {
          iteration1: 1,
          iteration2: 2,
          iteration3: 1,
          iteration4: 2,
          iteration5: 3
      }
      got = {
          iteration1: iteration1.iid,
          iteration2: iteration2.iid,
          iteration3: iteration3.iid,
          iteration4: iteration4.iid,
          iteration5: iteration5.iid
      }
      expect(got).to eq(want)
    end
  end
end
