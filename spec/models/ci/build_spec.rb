require 'spec_helper'

describe Ci::Build, models: true do
  let(:build) { create(:ci_build) }
  let(:test_trace) { 'This is a test' }

  describe '#trace' do
    it 'obfuscates project runners token' do
      allow(build).to receive(:raw_trace).and_return("Test: #{build.project.runners_token}")

      expect(build.trace).to eq("Test: xxxxxx")
    end

    it 'empty project runners token' do
      allow(build).to receive(:raw_trace).and_return(test_trace)
      # runners_token can't normally be set to nil
      allow(build.project).to receive(:runners_token).and_return(nil)

      expect(build.trace).to eq(test_trace)
    end
  end
end
