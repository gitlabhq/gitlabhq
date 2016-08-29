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
        before do
          build.trace = test_trace
          build.save
        end

        it { expect(build.has_trace_file?).to be_truthy }
        it { expect(build.trace).to eq(test_trace) }
      end

      context 'when trace is stored in old file' do
        before do
          build.trace = test_trace
          build.save

          build.project.ci_id = 999
          build.project.save

          FileUtils.mkdir_p(build.old_dir_to_trace)
          FileUtils.mv(build.path_to_trace, build.old_path_to_trace)
        end

        it { expect(build.has_trace_file?).to be_truthy }
        it { expect(build.trace).to eq(test_trace) }
      end

      context 'when there is stored in DB' do
        class Ci::Build
          def write_db_trace=(trace)
            write_attribute :trace, trace
          end
        end

        before do
          build.write_db_trace = test_trace
          build.save
        end

        it { expect(build.has_trace_file?).to be_falsey }
        it { expect(build.trace).to eq(test_trace) }
      end
    end
  end
end
