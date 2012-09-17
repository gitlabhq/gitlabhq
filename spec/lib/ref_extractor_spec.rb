require 'spec_helper'

describe RefExtractor do
  include RefExtractor

  let(:project) { double('project') }

  before do
    @project = project
    project.stub(:branches).and_return(['master', 'foo/bar/baz'])
    project.stub(:tags).and_return(['v1.0.0', 'v2.0.0'])
  end

  it "extracts a ref without a path" do
    extract_ref('master').should == ['master', '/']
  end

  it "extracts a valid branch ref" do
    extract_ref('foo/bar/baz/CHANGELOG').should == ['foo/bar/baz', '/CHANGELOG']
  end

  it "extracts a valid tag ref" do
    extract_ref('v2.0.0/CHANGELOG').should == ['v2.0.0', '/CHANGELOG']
  end

  it "extracts a valid commit ref" do
    extract_ref('f4b14494ef6abf3d144c28e4af0c20143383e062/CHANGELOG').should ==
      ['f4b14494ef6abf3d144c28e4af0c20143383e062', '/CHANGELOG']
  end

  it "falls back to a primitive split for an invalid ref" do
    extract_ref('stable/CHANGELOG').should == ['stable', '/CHANGELOG']
  end

  it "returns an empty pair when no @project is set" do
    @project = nil
    extract_ref('master/CHANGELOG').should == ['', '']
  end
end
