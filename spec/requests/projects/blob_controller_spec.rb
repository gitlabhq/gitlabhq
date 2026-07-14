# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects blob controller', feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

  before do
    sign_in(user)
  end

  describe 'GET diff_lines' do
    def do_get(**extra_params)
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: 'master/CHANGELOG'
      }

      get namespace_project_blob_diff_lines_path(params.merge(extra_params))
    end

    it 'renders the diff content' do
      do_get(since: 2, to: 3, offset: 10, closest_line_number: 1)

      expect(response.body).to be_present
    end

    it 'renders the specified number of lines including match line.' do
      do_get(since: 2, to: 4, offset: 0, closest_line_number: 1)

      expect(response.body).to include('@@').exactly(2).times
      expect(response.body).to include('<tr').exactly(4).times
      expect(response.body).to include('</tr>').exactly(4).times
    end

    it 'renders the specified number of lines without a match line.' do
      do_get(since: 1, to: 3, offset: 0, closest_line_number: 1)

      expect(response.body).to not_include('@@')
      expect(response.body).to include('<tr').exactly(3).times
      expect(response.body).to include('</tr>').exactly(3).times
    end

    context 'when view param is parallel' do
      it 'renders diff lines in parallel' do
        do_get(view: 'parallel', since: 2, to: 4, offset: 0, closest_line_number: 1)

        expect(response.body).to be_present
        expect(response.body).to include('data-testid="hunk-lines-parallel"')
      end
    end

    context 'when view param is inline' do
      it 'renders diff lines in inline' do
        do_get(view: 'inline', since: 2, to: 4, offset: 0, closest_line_number: 1)

        expect(response.body).to be_present
        expect(response.body).to include('data-testid="hunk-lines-inline"')
      end
    end

    context 'with missing required parameters' do
      it 'requires the since parameter' do
        expect do
          do_get(to: 4, offset: 0, closest_line_number: 1)
        end.to raise_error(ActionController::ParameterMissing)
      end

      it 'requires the to parameter' do
        expect do
          do_get(since: 2, offset: 0, closest_line_number: 1)
        end.to raise_error(ActionController::ParameterMissing)
      end

      it 'requires the offset parameter' do
        expect do
          do_get(since: 2, to: 4, closest_line_number: 1)
        end.to raise_error(ActionController::ParameterMissing)
      end
    end

    context 'when no hunk is found' do
      before do
        allow(Gitlab::Diff::ViewerHunk)
          .to receive(:init_from_expanded_lines).and_return([])
      end

      it 'returns 404' do
        do_get(since: 2, to: 6, offset: 10, closest_line_number: 1)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET show with an ambiguous branch and tag ref' do
    # When a branch and a tag share a name, the displayed ref and the download links
    # must stay anchored to the same ref so they cannot resolve to different content
    # (https://gitlab.com/gitlab-org/gitlab/-/issues/578988). The blob page threads
    # ref_type through its download links to keep them consistent.
    #
    # 'v1.1.0' exists as both a branch and a tag in the test repository, and
    # 'bar/branch-test.txt' only exists on the branch (it is absent from the tag).
    let_it_be(:public_project) { create(:project, :public, :repository) }

    let(:file_path) { 'v1.1.0/bar/branch-test.txt' }

    before do
      # 'v1.1.0' is expected to exist as both a branch and a tag in the test repository.
      raise 'fixture changed: v1.1.0 must be both a branch and a tag' unless
        public_project.repository.branch_exists?('v1.1.0') &&
          public_project.repository.tag_exists?('v1.1.0')

      # Render the page anonymously so the authenticated fork-button path, which is
      # unrelated to this regression, is not exercised.
      sign_out(user)
    end

    def get_show(ref_type:)
      get project_blob_path(public_project, file_path, ref_type: ref_type)
    end

    context 'when ref_type is heads' do
      it 'renders the branch blob with the ref type marker' do
        get_show(ref_type: 'heads')

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include('data-ref-type="heads"')
      end

      it_behaves_like 'archive download links anchored to the ref_type', ref_type: 'heads'
    end

    context 'when ref_type is tags' do
      it 'does not show the branch blob, redirecting to the tag tree instead' do
        get_show(ref_type: 'tags')

        # The file is absent from the tag, so the blob view cannot render the
        # branch content under the tag ref - it redirects to the tag tree.
        expect(response).to redirect_to(project_tree_path(public_project, 'v1.1.0'))
      end
    end

    context 'when ref_type is omitted' do
      it 'resolves the unqualified ref to the tag and redirects to the tag tree' do
        get_show(ref_type: nil)

        expect(response).to redirect_to(project_tree_path(public_project, 'v1.1.0'))
      end
    end
  end

  describe 'GET show for an ambiguous branch and tag whose names embed a ref prefix' do
    before do
      # Render anonymously so the authenticated fork-button path, which is unrelated
      # to this regression, is not exercised.
      sign_out(user)
    end

    def get_show(ref_type:)
      get project_blob_path(ambiguous_project, "#{ambiguous_ref}/#{file_path}", ref_type: ref_type)
    end

    context 'with a branch named "refs/tags/release" alongside a tag "release"' do
      include_context 'with an ambiguous branch and tag fixture',
        branch_name: 'refs/tags/release', tag_name: 'release'

      let(:ambiguous_ref) { 'refs/tags/release' }

      it_behaves_like 'an ambiguous ref with divergent branch and tag content'
      it_behaves_like 'archive download links anchored to the ref_type', ref_type: 'heads'
      it_behaves_like 'archive download links not anchored to a ref_type'
    end

    context 'with a tag named "refs/heads/release" alongside a branch "release"' do
      include_context 'with an ambiguous branch and tag fixture',
        branch_name: 'release', tag_name: 'refs/heads/release'

      let(:ambiguous_ref) { 'refs/heads/release' }

      it_behaves_like 'an ambiguous ref with divergent branch and tag content'
      it_behaves_like 'archive download links anchored to the ref_type', ref_type: 'tags'
      it_behaves_like 'archive download links not anchored to a ref_type'
    end
  end

  describe 'POST preview' do
    let(:content) { 'Some content' }

    def do_post(content)
      post namespace_project_preview_blob_path(
        namespace_id: project.namespace,
        project_id: project,
        id: 'master/CHANGELOG'
      ), params: { content: content }
    end

    context 'when content is within size limit' do
      it 'returns success and renders the preview' do
        do_post(content)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Content-Type']).to include('text/html')
      end
    end

    context 'when content exceeds size limit' do
      before do
        stub_const('Projects::BlobController::MAX_PREVIEW_CONTENT', 1.byte)
      end

      it 'returns payload too large error' do
        do_post(content)

        expect(response).to have_gitlab_http_status(:payload_too_large)
        expect(json_response['errors']).to include('Preview content too large')
      end
    end
  end
end
