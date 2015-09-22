require 'spec_helper'

describe ExtractsPath do
  include ExtractsPath
  include RepoHelpers
  include Gitlab::Application.routes.url_helpers

  let(:project) { double('project') }

  before do
    @project = project

    repo = double(ref_names: ['master', 'foo/bar/baz', 'v1.0.0', 'v2.0.0',
                              'release/app', 'release/app/v1.0.0'])
    allow(project).to receive(:repository).and_return(repo)
    allow(project).to receive(:path_with_namespace).
      and_return('gitlab/gitlab-ci')
  end

  describe '#assign_ref' do
    let(:ref) { sample_commit[:id] }
    let(:params) { { path: sample_commit[:line_code_path], ref: ref } }

    before do
      @project = create(:project)
    end

    it "log tree path should have no escape sequences" do
      assign_ref_vars
      expect(@logs_path).to eq("/#{@project.path_with_namespace}/refs/#{ref}/logs_tree/files/ruby/popen.rb")
    end

    context 'escaped sequences in ref' do
      let(:ref) { "improve%2Fawesome" }

      it "id should have no escape sequences" do
        assign_ref_vars
        expect(@ref).to eq('improve/awesome')
        expect(@logs_path).to eq("/#{@project.path_with_namespace}/refs/#{ref}/logs_tree/files/ruby/popen.rb")
      end
    end
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

      it "extracts the longest matching ref" do
        expect(extract_ref('release/app/v1.0.0/README.md')).to eq(
          ['release/app/v1.0.0', 'README.md'])
      end
    end

    context "with a path" do
      it "extracts a valid branch" do
        expect(extract_ref('foo/bar/baz/CHANGELOG')).to eq(
          ['foo/bar/baz', 'CHANGELOG'])
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
