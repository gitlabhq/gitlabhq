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

    context 'when rapid_diffs FF is disabled' do
      before do
        stub_feature_flags(rapid_diffs: false)
      end

      it 'returns 404' do
        do_get(since: 2, to: 6, offset: 10, closest_line_number: 1)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
