# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CompareController, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be_with_reload(:user) { create(:user, maintainer_of: project) }

  let(:from_ref) { '08f22f25' }
  let(:to_ref) { 'master' }

  let(:params) { { view: :inline } }

  subject(:send_request) do
    get project_compare_path(project, from: from_ref, to: to_ref, params: params)
  end

  before do
    sign_in(user)
  end

  def rendered_diff_files
    Nokogiri::HTML(response.body).css('[data-testid="rd-diff-file"]').map do |node|
      Gitlab::Json::SafeParser.parse(node['data-file-data']).slice('old_path', 'new_path')
    end
  end

  def initial_file
    node = Nokogiri::HTML(response.body).at_css('[data-rapid-diffs]')
    Gitlab::Json::SafeParser.parse(node['data-app-data'])['initial_file']
  end

  describe '#show' do
    it 'renders the rapid diffs app' do
      send_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to include('data-rapid-diffs')
    end

    context 'in file-by-file mode' do
      before do
        user.update!(view_diffs_file_by_file: true)
      end

      it 'renders exactly the file it names as the initial file' do
        send_request

        files = rendered_diff_files
        expect(files.size).to eq(1)
        expect(initial_file).to eq(files.first)
      end

      context 'with a file param that resolves to a file in the diff' do
        let(:params) { { view: :inline, file_path: 'files/whitespace' } }

        it 'renders that file and names it as the initial file' do
          send_request

          files = rendered_diff_files
          expect(files.size).to eq(1)
          expect(files.first).to include('new_path' => 'files/whitespace')
          expect(initial_file).to eq(files.first)
        end
      end

      context 'with a file param that is not part of the diff' do
        let(:params) { { view: :inline, file_path: 'does/not/exist.rb' } }

        it 'falls back to naming the first file, as the merge request and commit pages do' do
          send_request

          files = rendered_diff_files
          expect(files.size).to eq(1)
          expect(initial_file).to eq(files.first)
        end
      end
    end
  end
end
