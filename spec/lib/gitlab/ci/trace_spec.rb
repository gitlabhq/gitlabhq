require 'spec_helper'

describe Gitlab::Ci::Trace do
  let(:build) { create(:ci_build) }
  let(:trace) { described_class.new(build) }

  describe "associations" do
    it { expect(trace).to respond_to(:job) }
    it { expect(trace).to delegate_method(:old_trace).to(:job) }
  end

  describe '#html' do
    before do
      trace.set("12\n34")
    end

    it "returns formatted html" do
      expect(trace.html).to eq("12<br>34")
    end

    it "returns last line of formatted html" do
      expect(trace.html(last_lines: 1)).to eq("34")
    end
  end

  describe '#raw' do
    before do
      trace.set("12\n34")
    end

    it "returns raw output" do
      expect(trace.raw).to eq("12\n34")
    end

    it "returns last line of raw output" do
      expect(trace.raw(last_lines: 1)).to eq("34")
    end
  end

  describe '#extract_coverage' do
    let(:regex) { '\(\d+.\d+\%\) covered' }

    context 'matching coverage' do
      before do
        trace.set('Coverage 1033 / 1051 LOC (98.29%) covered')
      end

      it "returns valid coverage" do
        expect(trace.extract_coverage(regex)).to eq("98.29")
      end
    end

    context 'no coverage' do
      before do
        trace.set('No coverage')
      end

      it 'returs nil' do
        expect(trace.extract_coverage(regex)).to be_nil
      end
    end
  end

  describe '#set' do
    before do
      trace.set("12")
    end

    it "returns trace" do
      expect(trace.raw).to eq("12")
    end

    context 'overwrite trace' do
      before do
        trace.set("34")
      end

      it "returns new trace" do
        expect(trace.raw).to eq("34")
      end
    end

    context 'runners token' do
      let(:token) { 'my_secret_token' }

      before do
        build.project.update(runners_token: token)
        trace.set(token)
      end

      it "hides token" do
        expect(trace.raw).not_to include(token)
      end
    end

    context 'hides build token' do
      let(:token) { 'my_secret_token' }

      before do
        build.update(token: token)
        trace.set(token)
      end

      it "hides token" do
        expect(trace.raw).not_to include(token)
      end
    end
  end

  describe '#append' do
    before do
      trace.set("1234")
    end

    it "returns correct trace" do
      expect(trace.append("56", 4)).to eq(6)
      expect(trace.raw).to eq("123456")
    end

    context 'tries to append trace at different offset' do
      it "fails with append" do
        expect(trace.append("56", 2)).to eq(-4)
        expect(trace.raw).to eq("1234")
      end
    end

    context 'runners token' do
      let(:token) { 'my_secret_token' }

      before do
        build.project.update(runners_token: token)
        trace.append(token, 0)
      end

      it "hides token" do
        expect(trace.raw).not_to include(token)
      end
    end

    context 'build token' do
      let(:token) { 'my_secret_token' }

      before do
        build.update(token: token)
        trace.append(token, 0)
      end

      it "hides token" do
        expect(trace.raw).not_to include(token)
      end
    end
  end

  describe 'trace handling' do
    context 'trace does not exist' do
      it { expect(trace.exist?).to be(false) }
    end

    context 'new trace path is used' do
      before do
        trace.send(:ensure_directory)

        File.open(trace.send(:default_path), "w") do |file|
          file.write("data")
        end
      end

      it "trace exist" do
        expect(trace.exist?).to be(true)
      end

      it "can be erased" do
        trace.erase!
        expect(trace.exist?).to be(false)
      end
    end

    context 'deprecated path' do
      let(:path) { trace.send(:deprecated_path) }

      context 'with valid ci_id' do
        before do
          build.project.update(ci_id: 1000)

          FileUtils.mkdir_p(File.dirname(path))

          File.open(path, "w") do |file|
            file.write("data")
          end
        end

        it "trace exist" do
          expect(trace.exist?).to be(true)
        end

        it "can be erased" do
          trace.erase!
          expect(trace.exist?).to be(false)
        end
      end

      context 'without valid ci_id' do
        it "does not return deprecated path" do
          expect(path).to be_nil
        end
      end
    end

    context 'stored in database' do
      before do
        build.send(:write_attribute, :trace, "data")
      end

      it "trace exist" do
        expect(trace.exist?).to be(true)
      end

      it "can be erased" do
        trace.erase!
        expect(trace.exist?).to be(false)
      end

      it "returns database data" do
        expect(trace.raw).to eq("data")
      end
    end
  end
end
