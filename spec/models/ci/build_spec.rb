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

  describe '#has_trace_file?' do
    context 'when there is no trace' do
      it { expect(build.has_trace_file?).to be_falsey }
      it { expect(build.trace).to be_nil }
    end

    context 'when there is a trace' do
      context 'when trace is stored in file' do
        let(:build_with_trace) { create(:ci_build, :trace) }

        it { expect(build_with_trace.has_trace_file?).to be_truthy }
        it { expect(build_with_trace.trace).to eq('BUILD TRACE') }
      end

      context 'when trace is stored in old file' do
        before do
          allow(build.project).to receive(:ci_id).and_return(999)
          allow(File).to receive(:exist?).with(build.path_to_trace).and_return(false)
          allow(File).to receive(:exist?).with(build.old_path_to_trace).and_return(true)
          allow(File).to receive(:read).with(build.old_path_to_trace).and_return(test_trace)
        end

        it { expect(build.has_trace_file?).to be_truthy }
        it { expect(build.trace).to eq(test_trace) }
      end

      context 'when trace is stored in DB' do
        before do
          allow(build.project).to receive(:ci_id).and_return(nil)
          allow(build).to receive(:read_attribute).with(:trace).and_return(test_trace)
          allow(File).to receive(:exist?).with(build.path_to_trace).and_return(false)
          allow(File).to receive(:exist?).with(build.old_path_to_trace).and_return(false)
        end

        it { expect(build.has_trace_file?).to be_falsey }
        it { expect(build.trace).to eq(test_trace) }
      end
    end
  end

  describe '#trace_file_path' do
    context 'when trace is stored in file' do
      before do
        allow(build).to receive(:has_trace_file?).and_return(true)
        allow(build).to receive(:has_old_trace_file?).and_return(false)
      end

      it { expect(build.trace_file_path).to eq(build.path_to_trace) }
    end

    context 'when trace is stored in old file' do
      before do
        allow(build).to receive(:has_trace_file?).and_return(true)
        allow(build).to receive(:has_old_trace_file?).and_return(true)
      end

      it { expect(build.trace_file_path).to eq(build.old_path_to_trace) }
    end
  end
end
