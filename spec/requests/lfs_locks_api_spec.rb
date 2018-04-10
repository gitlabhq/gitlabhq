require 'spec_helper'

describe 'Git LFS File Locking API' do
  include WorkhorseHelpers

  let(:project)   { create(:project) }
  let(:master)    { create(:user) }
  let(:developer) { create(:user) }
  let(:guest)     { create(:user) }
  let(:path)      { 'README.md' }
  let(:headers) do
    {
      'Authorization' => authorization
    }.compact
  end

  shared_examples 'unauthorized request' do
    context 'when user is not authorized' do
      let(:authorization) { authorize_user(guest) }

      it 'returns a forbidden 403 response' do
        post_lfs_json url, body, headers

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  before do
    allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)

    project.add_developer(master)
    project.add_developer(developer)
    project.add_guest(guest)
  end

  describe 'Create File Lock endpoint' do
    let(:url)           { "#{project.http_url_to_repo}/info/lfs/locks" }
    let(:authorization) { authorize_user(developer) }
    let(:body)          { { path: path } }

    include_examples 'unauthorized request'

    context 'with an existent lock' do
      before do
        lock_file('README.md', developer)
      end

      it 'return an error message' do
        post_lfs_json url, body, headers

        expect(response).to have_gitlab_http_status(409)

        expect(json_response.keys).to match_array(%w(lock message documentation_url))
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

        expect(response).to have_gitlab_http_status(201)

        expect(json_response['lock'].keys).to match_array(%w(id path locked_at owner))
      end
    end
  end

  describe 'Listing File Locks endpoint' do
    let(:url)           { "#{project.http_url_to_repo}/info/lfs/locks" }
    let(:authorization) { authorize_user(developer) }

    include_examples 'unauthorized request'

    it 'returns the list of locked files' do
      lock_file('README.md', developer)
      lock_file('README', developer)

      do_get url, nil, headers

      expect(response).to have_gitlab_http_status(200)

      expect(json_response['locks'].size).to eq(2)
      expect(json_response['locks'].first.keys).to match_array(%w(id path locked_at owner))
    end
  end

  describe 'List File Locks for verification endpoint' do
    let(:url)           { "#{project.http_url_to_repo}/info/lfs/locks/verify" }
    let(:authorization) { authorize_user(developer) }

    include_examples 'unauthorized request'

    it 'returns the list of locked files grouped by owner' do
      lock_file('README.md', master)
      lock_file('README', developer)

      post_lfs_json url, nil, headers

      expect(response).to have_gitlab_http_status(200)

      expect(json_response['ours'].size).to eq(1)
      expect(json_response['ours'].first['path']).to eq('README')
      expect(json_response['theirs'].size).to eq(1)
      expect(json_response['theirs'].first['path']).to eq('README.md')
    end
  end

  describe 'Delete File Lock endpoint' do
    let!(:lock)         { lock_file('README.md', developer) }
    let(:url)           { "#{project.http_url_to_repo}/info/lfs/locks/#{lock[:id]}/unlock" }
    let(:authorization) { authorize_user(developer) }

    include_examples 'unauthorized request'

    context 'with an existent lock' do
      it 'deletes the lock' do
        post_lfs_json url, nil, headers

        expect(response).to have_gitlab_http_status(200)
      end

      it 'returns the deleted lock' do
        post_lfs_json url, nil, headers

        expect(json_response['lock'].keys).to match_array(%w(id path locked_at owner))
      end
    end
  end

  def lock_file(path, author)
    result = Lfs::LockFileService.new(project, author, { path: path }).execute

    result[:lock]
  end

  def authorize_user(user)
    ActionController::HttpAuthentication::Basic.encode_credentials(user.username, user.password)
  end

  def post_lfs_json(url, body = nil, headers = nil)
    post(url, body.try(:to_json), (headers || {}).merge('Content-Type' => LfsRequest::CONTENT_TYPE))
  end

  def do_get(url, params = nil,  headers = nil)
    get(url, (params || {}), (headers || {}).merge('Content-Type' => LfsRequest::CONTENT_TYPE))
  end

  def json_response
    @json_response ||= JSON.parse(response.body)
  end
end
