# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExtractsPath do
  include described_class
  include RepoHelpers
  include Gitlab::Routing

  let_it_be(:owner) { create(:user) }
  let_it_be(:container) { create(:project, :repository, creator: owner) }

  let(:request) { double('request') }

  before do
    @project = container
    ref_names = ['master', 'foo/bar/baz', 'v1.0.0', 'v2.0.0', 'release/app', 'release/app/v1.0.0']

    allow(container.repository).to receive(:ref_names).and_return(ref_names)
    allow(request).to receive(:format=)
  end

  describe '#assign_ref_vars' do
    let(:ref) { sample_commit[:id] }
    let(:params) { { path: sample_commit[:line_code_path], ref: ref } }

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
