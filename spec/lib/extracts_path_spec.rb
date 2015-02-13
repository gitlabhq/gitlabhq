require 'spec_helper'

describe ExtractsPath do
  include ExtractsPath

  let(:project) { double('project') }

  before do
    @project = project
    project.stub(repository: double(ref_names: ['master', 'foo/bar/baz', 'v1.0.0', 'v2.0.0']))
    project.stub(path_with_namespace: 'gitlab/gitlab-ci')
  end

  describe '#extract_ref' do
    it "returns an empty pair when no @project is set" do
      @project = nil
      expect(extract_ref('master/CHANGELOG')).to eq(['', ''])
    end

    context "without a path" do
      it "extracts a valid branch" do
        expect(extract_ref('master')).to eq(['master', ''])
      end

      it "extracts a valid tag" do
        expect(extract_ref('v2.0.0')).to eq(['v2.0.0', ''])
      end

      it "extracts a valid commit ref without a path" do
        expect(extract_ref('f4b14494ef6abf3d144c28e4af0c20143383e062')).to eq(
          ['f4b14494ef6abf3d144c28e4af0c20143383e062', '']
        )
      end

      it "falls back to a primitive split for an invalid ref" do
        expect(extract_ref('stable')).to eq(['stable', ''])
      end
    end

    context "with a path" do
      it "extracts a valid branch" do
        expect(extract_ref('foo/bar/baz/CHANGELOG')).to eq(['foo/bar/baz', 'CHANGELOG'])
      end

      it "extracts a valid tag" do
        expect(extract_ref('v2.0.0/CHANGELOG')).to eq(['v2.0.0', 'CHANGELOG'])
      end

      it "extracts a valid commit SHA" do
        expect(extract_ref('f4b14494ef6abf3d144c28e4af0c20143383e062/CHANGELOG')).to eq(
          ['f4b14494ef6abf3d144c28e4af0c20143383e062', 'CHANGELOG']
        )
      end

      it "falls back to a primitive split for an invalid ref" do
        expect(extract_ref('stable/CHANGELOG')).to eq(['stable', 'CHANGELOG'])
      end
    end
  end
end
