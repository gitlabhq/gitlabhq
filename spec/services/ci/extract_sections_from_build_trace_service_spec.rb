require 'spec_helper'

describe Ci::ExtractSectionsFromBuildTraceService, '#execute' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:build) { create(:ci_build, project: project) }

  subject { described_class.new(project, user) }

  shared_examples 'build trace has sections markers' do
    before do
      build.trace.set(File.read(expand_fixture_path('trace/trace_with_sections')))
    end

    it 'saves the correct extracted sections' do
      expect(build.trace_sections).to be_empty
      expect(subject.execute(build)).to be(true)
      expect(build.trace_sections).not_to be_empty
    end

    it "fails if trace_sections isn't empty" do
      expect(subject.execute(build)).to be(true)
      expect(build.trace_sections).not_to be_empty

      expect(subject.execute(build)).to be(false)
      expect(build.trace_sections).not_to be_empty
    end
  end

  shared_examples 'build trace has no sections markers' do
    before do
      build.trace.set('no markerts')
    end

    it 'extracts no sections' do
      expect(build.trace_sections).to be_empty
      expect(subject.execute(build)).to be(true)
      expect(build.trace_sections).to be_empty
    end
  end

  context 'when the build has no user' do
    it_behaves_like 'build trace has sections markers'
    it_behaves_like 'build trace has no sections markers'
  end

  context 'when the build has a valid user' do
    before do
      build.user = user
    end

    it_behaves_like 'build trace has sections markers'
    it_behaves_like 'build trace has no sections markers'
  end
end
