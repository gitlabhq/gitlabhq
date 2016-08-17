require 'spec_helper'

describe Ci::Charts, lib: true do
  context "build_times" do
    let(:project) { create(:empty_project) }
    let(:chart) { Ci::Charts::BuildTime.new(project) }

    subject { chart.build_times }

    before do
      create(:ci_empty_pipeline, project: project, duration: 120)
    end

    it 'returns build times in minutes' do
      is_expected.to contain_exactly(2)
    end

    it 'handles nil build times' do
      create(:ci_empty_pipeline, project: project, duration: nil)

      is_expected.to contain_exactly(2, 0)
    end
  end
end
