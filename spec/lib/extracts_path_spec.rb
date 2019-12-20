# frozen_string_literal: true

require 'spec_helper'

describe ExtractsPath do
  include described_class
  include RepoHelpers
  include Gitlab::Routing

  let(:project) { double('project') }
  let(:request) { double('request') }

  before do
    @project = project

    repo = double(ref_names: ['master', 'foo/bar/baz', 'v1.0.0', 'v2.0.0',
                              'release/app', 'release/app/v1.0.0'])
    allow(project).to receive(:repository).and_return(repo)
    allow(project).to receive(:full_path)
      .and_return('gitlab/gitlab-ci')
    allow(request).to receive(:format=)
  end

  describe '#assign_ref_vars' do
    let(:ref) { sample_commit[:id] }
    let(:params) { { path: sample_commit[:line_code_path], ref: ref } }

    before do
      @project = create(:project, :repository)
    end

    it "log tree path has no escape sequences" do
      assign_ref_vars
      expect(@logs_path).to eq("/#{@project.full_path}/refs/#{ref}/logs_tree/files/ruby/popen.rb")
    end

    context 'ref contains %20' do
      let(:ref) { 'foo%20bar' }

      it 'is not converted to a space in @id' do
        @project.repository.add_branch(@project.owner, 'foo%20bar', 'master')

        assign_ref_vars

        expect(@id).to start_with('foo%20bar/')
      end
    end

    context 'ref contains trailing space' do
      let(:ref) { 'master ' }

      it 'strips surrounding space' do
        assign_ref_vars

        expect(@ref).to eq('master')
      end
    end

    context 'ref contains leading space' do
      let(:ref) { ' master ' }

      it 'strips surrounding space' do
        assign_ref_vars

        expect(@ref).to eq('master')
      end
    end

    context 'ref contains space in the middle' do
      let(:ref) { 'master plan ' }

      it 'returns 404' do
        expect(self).to receive(:render_404)

        assign_ref_vars
      end
    end

    context 'path contains space' do
      let(:params) { { path: 'with space', ref: '38008cb17ce1466d8fec2dfa6f6ab8dcfe5cf49e' } }

      it 'is not converted to %20 in @path' do
        assign_ref_vars

        expect(@path).to eq(params[:path])
      end
    end

    context 'subclass overrides get_id' do
      it 'uses ref returned by get_id' do
        allow_next_instance_of(self.class) do |instance|
          allow(instance).to receive(:get_id) { '38008cb17ce1466d8fec2dfa6f6ab8dcfe5cf49e' }
        end

        assign_ref_vars

        expect(@id).to eq(get_id)
      end
    end

    context 'ref only exists without .atom suffix' do
      context 'with a path' do
        let(:params) { { ref: 'v1.0.0.atom', path: 'README.md' } }

        it 'renders a 404' do
          expect(self).to receive(:render_404)

          assign_ref_vars
        end
      end

      context 'without a path' do
        let(:params) { { ref: 'v1.0.0.atom' } }

        before do
          assign_ref_vars
        end

        it 'sets the un-suffixed version as @ref' do
          expect(@ref).to eq('v1.0.0')
        end

        it 'sets the request format to Atom' do
          expect(request).to have_received(:format=).with(:atom)
        end
      end
    end

    context 'ref exists with .atom suffix' do
      context 'with a path' do
        let(:params) { { ref: 'master.atom', path: 'README.md' } }

        before do
          repository = @project.repository
          allow(repository).to receive(:commit).and_call_original
          allow(repository).to receive(:commit).with('master.atom').and_return(repository.commit('master'))

          assign_ref_vars
        end

        it 'sets the suffixed version as @ref' do
          expect(@ref).to eq('master.atom')
        end

        it 'does not change the request format' do
          expect(request).not_to have_received(:format=)
        end
      end

      context 'without a path' do
        let(:params) { { ref: 'master.atom' } }

        before do
          repository = @project.repository
          allow(repository).to receive(:commit).and_call_original
          allow(repository).to receive(:commit).with('master.atom').and_return(repository.commit('master'))
        end

        it 'sets the suffixed version as @ref' do
          assign_ref_vars

          expect(@ref).to eq('master.atom')
        end

        it 'does not change the request format' do
          expect(request).not_to receive(:format=)

          assign_ref_vars
        end
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
          %w(f4b14494ef6abf3d144c28e4af0c20143383e062 CHANGELOG)
        )
      end

      it "falls back to a primitive split for an invalid ref" do
        expect(extract_ref('stable/CHANGELOG')).to eq(%w(stable CHANGELOG))
      end
    end
  end

  describe '#extract_ref_without_atom' do
    it 'ignores any matching refs suffixed with atom' do
      expect(extract_ref_without_atom('master.atom')).to eq('master')
    end

    it 'returns the longest matching ref' do
      expect(extract_ref_without_atom('release/app/v1.0.0.atom')).to eq('release/app/v1.0.0')
    end

    it 'returns nil if there are no matching refs' do
      expect(extract_ref_without_atom('foo.atom')).to eq(nil)
    end
  end

  describe '#lfs_blob_ids' do
    let(:tag) { @project.repository.add_tag(@project.owner, 'my-annotated-tag', 'master', 'test tag') }
    let(:ref) { tag.target }
    let(:params) { { ref: ref, path: 'README.md' } }

    before do
      @project = create(:project, :repository)
    end

    it 'handles annotated tags' do
      assign_ref_vars

      expect(lfs_blob_ids).to eq([])
    end
  end
end
