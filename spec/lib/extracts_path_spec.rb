# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExtractsPath, feature_category: :source_code_management do
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
    let(:params) { ActionController::Parameters.new(path: path, ref: ref) }

    it_behaves_like 'assigns ref vars'

    describe 'ref_type detection' do
      subject { assign_ref_vars.then { @ref_type } }

      context 'when ref is a branch' do
        let(:ref) { container.default_branch }

        it { is_expected.to eq 'heads' }
      end

      context 'when ref is a tag' do
        let(:ref) { container.repository.tag_names.first }

        it { is_expected.to eq 'tags' }
      end

      context 'when ref is ambiguous' do
        let(:ref) { 'ambiguous' }

        before do
          container.repository.create_branch(ref, sample_commit[:id])
          container.repository.expire_branches_cache
          container.repository.add_tag(container.owner, ref, sample_commit[:id])
          container.repository.expire_tags_cache
        end

        after do
          container.repository.rm_branch(container.owner, ref)
          container.repository.rm_tag(container.owner, ref)
        end

        it { is_expected.to be_nil }
      end
    end

    context 'when ref and path have incorrect format' do
      let(:ref) { { wrong: :format } }
      let(:path) { { also: :wrong } }

      it 'does not raise an exception' do
        expect(self).to receive(:render_404)
        expect { assign_ref_vars }.not_to raise_error
      end
    end

    context 'when a ref_type parameter is provided' do
      let(:params) { ActionController::Parameters.new(path: path, ref: ref, ref_type: 'tags') }

      it 'sets a fully_qualified_ref variable' do
        fully_qualified_ref = "refs/tags/#{ref}"
        expect(container.repository).to receive(:commit).with(fully_qualified_ref)
        expect(self).to receive(:render_404)

        assign_ref_vars
        expect(@fully_qualified_ref).to eq(fully_qualified_ref)
      end
    end

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

    context 'ref only exists without .json suffix' do
      context 'with a path' do
        let(:ref) { 'v1.0.0.json' }
        let(:path) { 'README.md' }

        it 'renders a 404' do
          expect(self).to receive(:render_404)

          assign_ref_vars
        end
      end

      context 'without a path' do
        let(:ref) { 'v1.0.0.json' }
        let(:path) { nil }

        before do
          assign_ref_vars
        end

        it 'sets the un-suffixed version as @ref' do
          expect(@ref).to eq('v1.0.0')
        end

        it 'sets the request format to JSON' do
          expect(request).to have_received(:format=).with(:json)
        end
      end
    end

    context 'ref exists with .json suffix' do
      before do
        repository = @project.repository
        allow(repository).to receive(:commit).and_call_original
        allow(repository).to receive(:commit).with('master.json').and_return(repository.commit('master'))
      end

      context 'with a path' do
        let(:ref) { 'master.json' }
        let(:path) { 'README.md' }

        before do
          assign_ref_vars
        end

        it 'sets the suffixed version as @ref' do
          expect(@ref).to eq('master.json')
        end

        it 'does not change the request format' do
          expect(request).not_to have_received(:format=)
        end
      end

      context 'without a path' do
        let(:ref) { 'master.json' }
        let(:path) { nil }

        before do
          assign_ref_vars
        end

        it 'sets the suffixed version as @ref' do
          expect(@ref).to eq('master.json')
        end

        it 'does not change the request format' do
          expect(request).not_to have_received(:format=)
        end
      end
    end

    context 'ref only exists without .atom suffix' do
      context 'with a path' do
        let(:ref) { 'v1.0.0.atom' }
        let(:path) { 'README.md' }

        it 'renders a 404' do
          expect(self).to receive(:render_404)

          assign_ref_vars
        end
      end

      context 'without a path' do
        let(:ref) { 'v1.0.0.atom' }
        let(:path) { nil }

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
      before do
        repository = @project.repository
        allow(repository).to receive(:commit).and_call_original
        allow(repository).to receive(:commit).with('master.atom').and_return(repository.commit('master'))
      end

      context 'with a path' do
        let(:ref) { 'master.atom' }
        let(:path) { 'README.md' }

        before do
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
        let(:ref) { 'master.atom' }
        let(:path) { nil }

        before do
          assign_ref_vars
        end

        it 'sets the suffixed version as @ref' do
          expect(@ref).to eq('master.atom')
        end

        it 'does not change the request format' do
          expect(request).not_to have_received(:format=)
        end
      end
    end

    context 'ref and path are nil' do
      let(:path) { nil }
      let(:ref) { nil }

      it 'does not set commit' do
        expect(self).to receive(:render_404)
        expect(container.repository).not_to receive(:commit).with('')

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

  describe '#ref_type' do
    subject { ref_type }

    let(:params) { ActionController::Parameters.new(ref_type: ref_type_input) }

    where(:ref_type_input, :ref_type_output) do
      [
        %w[heads heads],
        %w[tags tags],
        %w[tAgS tags],
        [nil, nil],
        ['invalid', nil],
        [{ 'just' => 'hash' }, nil]
      ]
    end

    with_them do
      it "returns and assigns expected value" do
        is_expected.to eq(ref_type_output)
        expect(@ref_type).to eq(ref_type_output)
      end
    end
  end

  describe '#path_present?' do
    it 'returns falsey when path is nil' do
      @path = nil
      expect(path_present?).to be_falsey
    end

    it 'returns falsey when path is empty' do
      @path = ''
      expect(path_present?).to be_falsey
    end

    it 'returns true when path is whitespace-only' do
      @path = ' '
      expect(path_present?).to be true
    end

    it 'returns true when path is a real path' do
      @path = 'app/models'
      expect(path_present?).to be true
    end
  end

  describe '#extract_ref_and_format' do
    it 'ignores any matching refs suffixed with atom' do
      expect(extract_ref_and_format('master.atom')).to eq(['master', :atom])
    end

    it 'ignores any matching refs suffixed with json' do
      expect(extract_ref_and_format('master.json')).to eq(['master', :json])
    end

    it 'returns the exactly matching ref' do
      expect(extract_ref_and_format('release/app/v1.0.0.atom')).to eq(['release/app/v1.0.0', :atom])
    end

    it 'raises an error if there are no matching refs' do
      expect { extract_ref_and_format('foo.atom') }.to raise_error(ExtractsPath::InvalidPathError)
    end
  end

  describe '#verify_gitaly_availability!' do
    let(:ref) { 'master' }
    let(:path) { nil }
    let(:params) { ActionController::Parameters.new(path: path, ref: ref) }

    before do
      allow(self).to receive(:render_404)
    end

    context 'when controller does not include HandlesGitalyErrors' do
      before do
        allow(self.class).to receive(:include?).and_call_original
        allow(self.class).to receive(:include?).with(HandlesGitalyErrors).and_return(false)
      end

      it 'does not perform the health check' do
        expect(Gitlab::GitalyClient::HealthCheckService).not_to receive(:new)

        verify_gitaly_availability!
      end
    end

    context 'when controller includes HandlesGitalyErrors' do
      before do
        allow(self.class).to receive(:include?).and_call_original
        allow(self.class).to receive(:include?).with(HandlesGitalyErrors).and_return(true)
      end

      context 'when repository_container is nil' do
        before do
          @project = nil
        end

        it 'does not perform the health check' do
          expect(Gitlab::GitalyClient::HealthCheckService).not_to receive(:new)

          verify_gitaly_availability!
        end
      end

      context 'when Gitaly is available' do
        before do
          allow_next_instance_of(Gitlab::GitalyClient::HealthCheckService) do |service|
            allow(service).to receive(:check).and_return({ success: true })
          end
        end

        it 'does not raise an error' do
          expect { verify_gitaly_availability! }.not_to raise_error
        end
      end

      context 'when Gitaly is unavailable' do
        before do
          allow_next_instance_of(Gitlab::GitalyClient::HealthCheckService) do |service|
            allow(service).to receive(:check).and_return({ success: false, message: 'Gitaly unavailable' })
          end
        end

        it 'raises Gitlab::Git::CommandError' do
          expect { verify_gitaly_availability! }.to raise_error(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end

        context 'when health check returns no message' do
          before do
            allow_next_instance_of(Gitlab::GitalyClient::HealthCheckService) do |service|
              allow(service).to receive(:check).and_return({ success: false, message: nil })
            end
          end

          it 'raises with default message' do
            expect { verify_gitaly_availability! }.to raise_error(Gitlab::Git::CommandError, 'Gitaly is not available')
          end
        end
      end
    end
  end

  describe '#assign_ref_vars Gitaly availability check' do
    let(:path) { nil }
    let(:params) { ActionController::Parameters.new(path: path, ref: ref) }

    before do
      allow(self).to receive(:render_404)
      allow(self.class).to receive(:include?).and_call_original
      allow(self.class).to receive(:include?).with(HandlesGitalyErrors).and_return(true)
    end

    context 'when @ref is blank' do
      let(:ref) { '' }

      it 'does not call verify_gitaly_availability!' do
        expect(self).not_to receive(:verify_gitaly_availability!)

        assign_ref_vars
      end
    end

    context 'when @ref is present but @commit is nil' do
      let(:ref) { 'nonexistent-branch' }

      before do
        allow(container.repository).to receive(:commit).and_return(nil)
      end

      it 'calls verify_gitaly_availability!' do
        expect(self).to receive(:verify_gitaly_availability!)

        assign_ref_vars
      end
    end

    context 'when @commit is present' do
      let(:ref) { 'master' }

      it 'does not call verify_gitaly_availability!' do
        expect(self).not_to receive(:verify_gitaly_availability!)

        assign_ref_vars
      end
    end
  end
end
