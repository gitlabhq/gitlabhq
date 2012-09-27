require 'spec_helper'

describe ExtractsPath do
  include ExtractsPath

  let(:project) { double('project') }

  before do
    @project = project
    project.stub(:branches).and_return(['master', 'foo/bar/baz'])
    project.stub(:tags).and_return(['v1.0.0', 'v2.0.0'])
  end

  describe '#extract_ref' do
    it "returns an empty pair when no @project is set" do
      @project = nil
      extract_ref('master/CHANGELOG').should == ['', '']
    end

    context "without a path" do
      it "extracts a valid branch" do
        extract_ref('master').should == ['master', '']
      end

      it "extracts a valid tag" do
        extract_ref('v2.0.0').should == ['v2.0.0', '']
      end

      it "extracts a valid commit ref without a path" do
        extract_ref('f4b14494ef6abf3d144c28e4af0c20143383e062').should ==
          ['f4b14494ef6abf3d144c28e4af0c20143383e062', '']
      end

      it "falls back to a primitive split for an invalid ref" do
        extract_ref('stable').should == ['stable', '']
      end
    end

    context "with a path" do
      it "extracts a valid branch" do
        extract_ref('foo/bar/baz/CHANGELOG').should == ['foo/bar/baz', 'CHANGELOG']
      end

      it "extracts a valid tag" do
        extract_ref('v2.0.0/CHANGELOG').should == ['v2.0.0', 'CHANGELOG']
      end

      it "extracts a valid commit SHA" do
        extract_ref('f4b14494ef6abf3d144c28e4af0c20143383e062/CHANGELOG').should ==
          ['f4b14494ef6abf3d144c28e4af0c20143383e062', 'CHANGELOG']
      end

      it "falls back to a primitive split for an invalid ref" do
        extract_ref('stable/CHANGELOG').should == ['stable', 'CHANGELOG']
      end
    end
  end
end
