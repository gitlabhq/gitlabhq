# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExtractsPath do
  include described_class
  include RepoHelpers
  include Gitlab::Routing

  # Make url_for work
  def default_url_options
    { controller: 'projects/blob', action: 'show', namespace_id: @project.namespace.path, project_id: @project.path }
  end

  let_it_be(:owner) { create(:user) }
  let_it_be(:container) { create(:project, :repository, creator: owner) }

  let(:request) { double('request') }
  let(:flash) { {} }
  let(:redirect_renamed_default_branch?) { true }

  before do
    @project = container
    ref_names = ['master', 'foo/bar/baz', 'v1.0.0', 'v2.0.0', 'release/app', 'release/app/v1.0.0']

    allow(container.repository).to receive(:ref_names).and_return(ref_names)
    allow(request).to receive(:format=)
    allow(request).to receive(:get?)
    allow(request).to receive(:head?)
  end

  describe '#assign_ref_vars' do
    let(:ref) { sample_commit[:id] }
    let(:path) { sample_commit[:line_code_path] }
    let(:params) { { path: path, ref: ref } }

    it_behaves_like 'assigns ref vars'

    it 'log tree path has no escape sequences' do
      assign_ref_vars

      expect(@logs_path).to eq("/#{@project.full_path}/-/refs/#{ref}/logs_tree/files/ruby/popen.rb")
    end

    context 'ref contains space in the middle' do
      let(:ref) { 'master plan ' }

      it 'returns 404' do
        expect(self).to receive(:render_404)

        assign_ref_vars
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

    context 'ref and path are nil' do
      let(:params) { { path: nil, ref: nil } }

      it 'does not set commit' do
        expect(container.repository).not_to receive(:commit).with('')
        expect(self).to receive(:render_404)

        assign_ref_vars

        expect(@commit).to be_nil
      end
    end

    context 'ref points to a previous default branch' do
      let(:ref) { 'develop' }

      before do
        @project.update!(previous_default_branch: ref)

        allow(@project).to receive(:default_branch).and_return('foo')
      end

      it 'redirects to the new default branch for a GET request' do
        allow(request).to receive(:get?).and_return(true)

        expect(self).to receive(:redirect_to).with("http://localhost/#{@project.full_path}/-/blob/foo/#{path}")
        expect(self).not_to receive(:render_404)

        assign_ref_vars

        expect(@commit).to be_nil
        expect(flash[:notice]).to match(/default branch/)
      end

      it 'redirects to the new default branch for a HEAD request' do
        allow(request).to receive(:head?).and_return(true)

        expect(self).to receive(:redirect_to).with("http://localhost/#{@project.full_path}/-/blob/foo/#{path}")
        expect(self).not_to receive(:render_404)

        assign_ref_vars

        expect(@commit).to be_nil
        expect(flash[:notice]).to match(/default branch/)
      end

      it 'returns 404 for any other request type' do
        expect(self).not_to receive(:redirect_to)
        expect(self).to receive(:render_404)

        assign_ref_vars

        expect(@commit).to be_nil
        expect(flash).to be_empty
      end

      context 'redirect behaviour is disabled' do
        let(:redirect_renamed_default_branch?) { false }

        it 'returns 404 for a GET request' do
          allow(request).to receive(:get?).and_return(true)

          expect(self).not_to receive(:redirect_to)
          expect(self).to receive(:render_404)

          assign_ref_vars

          expect(@commit).to be_nil
          expect(flash).to be_empty
        end
      end
    end
  end

  it_behaves_like 'extracts refs'

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
