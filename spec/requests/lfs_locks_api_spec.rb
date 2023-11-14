# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Git LFS File Locking API', feature_category: :source_code_management do
  include LfsHttpHelpers
  include WorkhorseHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:path) { 'README.md' }

  let(:user) { developer }
  let(:headers) do
    {
      'Authorization' => authorize_user
    }.compact
  end

  shared_examples 'unauthorized request' do
    context 'when user does not have download permission' do
      let(:user) { guest }

      it 'returns a 404 response' do
        post_lfs_json url, body, headers

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user does not have upload permission' do
      let(:user) { reporter }

      it 'returns a 403 response' do
        post_lfs_json url, body, headers

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  before do
    allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)

    project.add_maintainer(maintainer)
    project.add_developer(developer)
    project.add_reporter(reporter)
    project.add_guest(guest)
  end

  describe 'Create File Lock endpoint' do
    let(:url) { "#{project.http_url_to_repo}/info/lfs/locks" }
    let(:body) { { path: path } }

    include_examples 'unauthorized request'

    context 'with an existent lock' do
      before do
        lock_file('README.md', developer)
      end

      it 'return an error message' do
        post_lfs_json url, body, headers

        expect(response).to have_gitlab_http_status(:conflict)

        expect(json_response.keys).to match_array(%w[lock message documentation_url])
        expect(json_response['message']).to match(/already locked/)
      end

      it 'returns the existen lock' do
        post_lfs_json url, body, headers

        expect(json_response['lock']['path']).to eq('README.md')
      end
    end

    context 'without an existent lock' do
      it 'creates the lock' do
        post_lfs_json url, body, headers

        expect(response).to have_gitlab_http_status(:created)

        expect(json_response['lock'].keys).to match_array(%w[id path locked_at owner])
      end
    end
  end

  describe 'Listing File Locks endpoint' do
    let(:url) { "#{project.http_url_to_repo}/info/lfs/locks" }

    include_examples 'unauthorized request'

    it 'returns the list of locked files' do
      lock_file('README.md', developer)
      lock_file('README', developer)

      do_get url, nil, headers

      expect(response).to have_gitlab_http_status(:ok)

      expect(json_response['locks'].size).to eq(2)
      expect(json_response['locks'].first.keys).to match_array(%w[id path locked_at owner])
    end
  end

  describe 'List File Locks for verification endpoint' do
    let(:url) { "#{project.http_url_to_repo}/info/lfs/locks/verify" }

    include_examples 'unauthorized request'

    it 'returns the list of locked files grouped by owner' do
      lock_file('README.md', maintainer)
      lock_file('README', developer)

      post_lfs_json url, nil, headers

      expect(response).to have_gitlab_http_status(:ok)

      expect(json_response['ours'].size).to eq(1)
      expect(json_response['ours'].first['path']).to eq('README')
      expect(json_response['theirs'].size).to eq(1)
      expect(json_response['theirs'].first['path']).to eq('README.md')
    end
  end

  describe 'Delete File Lock endpoint' do
    let!(:lock) { lock_file('README.md', developer) }
    let(:url) { "#{project.http_url_to_repo}/info/lfs/locks/#{lock[:id]}/unlock" }

    include_examples 'unauthorized request'

    context 'with an existent lock' do
      it 'deletes the lock' do
        post_lfs_json url, nil, headers

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns the deleted lock' do
        post_lfs_json url, nil, headers

        expect(json_response['lock'].keys).to match_array(%w[id path locked_at owner])
      end

      context 'when a maintainer uses force' do
        let(:user) { maintainer }

        it 'deletes the lock' do
          project.add_maintainer(maintainer)
          post_lfs_json url, { force: true }, headers

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  def lock_file(path, author)
    result = Lfs::LockFileService.new(project, author, { path: path }).execute

    result[:lock]
  end

  def do_get(url, params = nil, headers = nil)
    get(url, params: (params || {}), headers: (headers || {}).merge('Content-Type' => LfsRequest::CONTENT_TYPE))
  end
end
