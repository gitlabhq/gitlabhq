# frozen_string_literal: true

RSpec.shared_examples 'wiki controller actions' do
  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let(:container) { raise NotImplementedError }
  let(:routing_params) { raise NotImplementedError }
  let(:wiki) { Wiki.for_container(container, user) }
  let(:wiki_title) { 'page title test' }

  before do
    create(:wiki_page, wiki: wiki, title: wiki_title, content: 'hello world')

    sign_in(user)
  end

  shared_examples 'recovers from git timeout' do
    let(:method_name) { :page }

    context 'when we encounter git command errors' do
      it 'renders the appropriate template', :aggregate_failures do
        expect(controller).to receive(method_name) do
          raise ::Gitlab::Git::CommandTimedOut, 'Deadline Exceeded'
        end

        request

        expect(response).to render_template('shared/wikis/git_error')
      end
    end
  end

  describe 'GET #new' do
    subject(:request) { get :new, params: routing_params }

    it 'redirects to #show and appends a `random_title` param' do
      request

      expect(response).to be_redirect
      expect(response.redirect_url).to match(%r{
        #{Regexp.quote(wiki.wiki_base_path)} # wiki base path
        /[-\h]{36}                           # page slug
        \?random_title=true\Z                # random_title param
      }x)
    end

    context 'when the wiki repository cannot be created' do
      before do
        expect(Wiki).to receive(:for_container).and_return(wiki)
        expect(wiki).to receive(:wiki) { raise Wiki::CouldNotCreateWikiError }
      end

      it 'redirects to the wiki container and displays an error message' do
        request

        expect(response).to redirect_to(container)
        expect(flash[:notice]).to eq('Could not create Wiki Repository at this time. Please try again later.')
      end
    end
  end

  describe 'GET #pages' do
    before do
      get :pages, params: routing_params.merge(id: wiki_title)
    end

    it_behaves_like 'recovers from git timeout' do
      subject(:request) { get :pages, params: routing_params.merge(id: wiki_title) }

      let(:method_name) { :wiki_pages }
    end

    it 'assigns the page collections' do
      expect(assigns(:wiki_pages)).to contain_exactly(an_instance_of(WikiPage))
      expect(assigns(:wiki_entries)).to contain_exactly(an_instance_of(WikiPage))
    end

    it 'does not load the page content' do
      expect(assigns(:page)).to be_nil
    end

    it 'does not load the sidebar' do
      expect(assigns(:sidebar_wiki_entries)).to be_nil
      expect(assigns(:sidebar_limited)).to be_nil
    end

    context 'when the request is of non-html format' do
      it 'returns a 404 error' do
        get :pages, params: routing_params.merge(format: 'json')

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #history' do
    before do
      allow(controller)
        .to receive(:can?)
        .with(any_args)
        .and_call_original

      # The :create_wiki permission is irrelevant to reading history.
      expect(controller)
        .not_to receive(:can?)
        .with(anything, :create_wiki, any_args)

      allow(controller)
        .to receive(:can?)
        .with(anything, :read_wiki, any_args)
        .and_return(allow_read_wiki)
    end

    shared_examples 'fetching history' do |expected_status|
      before do
        get :history, params: routing_params.merge(id: wiki_title)
      end

      it "returns status #{expected_status}" do
        expect(response).to have_gitlab_http_status(expected_status)
      end
    end

    it_behaves_like 'recovers from git timeout' do
      subject(:request) { get :history, params: routing_params.merge(id: wiki_title) }

      let(:allow_read_wiki)   { true }
    end

    it_behaves_like 'fetching history', :ok do
      let(:allow_read_wiki)   { true }

      it 'assigns @commits' do
        expect(assigns(:commits)).to be_present
      end
    end

    it_behaves_like 'fetching history', :not_found do
      let(:allow_read_wiki)   { false }
    end
  end

  describe 'GET #diff' do
    context 'when commit exists' do
      it 'renders the diff' do
        get :diff, params: routing_params.merge(id: wiki_title, version_id: wiki.repository.commit.id)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('shared/wikis/diff')
        expect(assigns(:diffs)).to be_a(Gitlab::Diff::FileCollection::Base)
        expect(assigns(:diff_notes_disabled)).to be(true)
      end
    end

    context 'when commit does not exist' do
      it 'returns a 404 error' do
        get :diff, params: routing_params.merge(id: wiki_title, version_id: 'invalid')

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when page does not exist' do
      it 'returns a 404 error' do
        get :diff, params: routing_params.merge(id: 'invalid')

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it_behaves_like 'recovers from git timeout' do
      subject(:request) { get :diff, params: routing_params.merge(id: wiki_title, version_id: wiki.repository.commit.id) }
    end
  end

  describe 'GET #show' do
    render_views

    let(:random_title) { nil }

    subject(:request) { get :show, params: routing_params.merge(id: id, random_title: random_title) }

    context 'when page exists' do
      let(:id) { wiki_title }

      it_behaves_like 'recovers from git timeout'

      it 'renders the page' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('shared/wikis/show')
        expect(assigns(:page).title).to eq(wiki_title)
        expect(assigns(:sidebar_wiki_entries)).to contain_exactly(an_instance_of(WikiPage))
        expect(assigns(:sidebar_limited)).to be(false)
      end

      context 'the sidebar fails to load' do
        before do
          allow(Wiki).to receive(:for_container).and_return(wiki)
          wiki.wiki
          expect(wiki).to receive(:find_sidebar) do
            raise ::Gitlab::Git::CommandTimedOut, 'Deadline Exceeded'
          end
        end

        it 'renders the page, and marks the sidebar as failed' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('shared/wikis/_sidebar')
          expect(assigns(:page).title).to eq(wiki_title)
          expect(assigns(:sidebar_page)).to be_nil
          expect(assigns(:sidebar_wiki_entries)).to be_nil
          expect(assigns(:sidebar_limited)).to be_nil
          expect(assigns(:sidebar_error)).to be_a_kind_of(::Gitlab::Git::CommandError)
        end
      end

      context 'page view tracking' do
        it_behaves_like 'tracking unique hll events' do
          let(:target_id) { 'wiki_action' }
          let(:expected_type) { instance_of(String) }
        end

        it 'increases the page view counter' do
          expect do
            request

            expect(response).to have_gitlab_http_status(:ok)
          end.to change { Gitlab::UsageDataCounters::WikiPageCounter.read(:view) }.by(1)
        end
      end

      context 'when page content encoding is invalid' do
        it 'sets flash error' do
          allow(controller).to receive(:valid_encoding?).and_return(false)

          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('shared/wikis/show')
          expect(flash[:notice]).to eq(_('The content of this page is not encoded in UTF-8. Edits can only be made via the Git repository.'))
        end
      end
    end

    context 'when the page does not exist' do
      let(:id) { 'does not exist' }

      context 'when the user can create pages' do
        before do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('shared/wikis/edit')
        end

        it 'builds a new wiki page with the id as the title' do
          expect(assigns(:page).title).to eq(id)
        end

        context 'when a random_title param is present' do
          let(:random_title) { true }

          it 'builds a new wiki page with no title' do
            expect(assigns(:page).title).to be_empty
          end
        end
      end

      context 'when the user cannot create pages' do
        before do
          sign_out(:user)
        end

        it 'shows the empty state' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('shared/wikis/empty')
        end
      end
    end

    context 'when page is a file' do
      include WikiHelpers

      where(:file_name) { ['dk.png', 'unsanitized.svg', 'git-cheat-sheet.pdf'] }

      with_them do
        let(:id) { upload_file_to_wiki(wiki, user, file_name) }

        it 'delivers the file with the correct headers' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers['Content-Disposition']).to match(/^inline/)
          expect(response.headers[Gitlab::Workhorse::DETECT_HEADER]).to eq('true')
          expect(response.cache_control[:public]).to be(false)
          expect(response.headers['Cache-Control']).to eq('no-store')
        end
      end
    end
  end

  describe 'POST #preview_markdown' do
    it 'renders json in a correct format' do
      post :preview_markdown, params: routing_params.merge(id: 'page/path', text: '*Markdown* text')

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.keys).to match_array(%w(body references))
    end
  end

  shared_examples 'edit action' do
    context 'when the page does not exist' do
      let(:id_param) { 'invalid' }

      it 'redirects to show' do
        request

        expect(response).to redirect_to_wiki(wiki, 'invalid')
      end
    end

    context 'when id param is blank' do
      let(:id_param) { ' ' }

      it 'redirects to the home page' do
        request

        expect(response).to redirect_to_wiki(wiki, 'home')
      end
    end

    context 'when page content encoding is invalid' do
      it 'redirects to show' do
        allow(controller).to receive(:valid_encoding?).and_return(false)

        request

        expect(response).to redirect_to_wiki(wiki, wiki.list_pages.first)
      end
    end

    context 'when the page has nil content' do
      let(:page) { create(:wiki_page) }

      it 'redirects to show' do
        allow(page).to receive(:content).and_return(nil)
        allow(controller).to receive(:page).and_return(page)

        request

        expect(response).to redirect_to_wiki(wiki, page)
      end
    end
  end

  describe 'GET #edit' do
    let(:id_param) { wiki_title }

    subject(:request) { get(:edit, params: routing_params.merge(id: id_param)) }

    it_behaves_like 'edit action'
    it_behaves_like 'recovers from git timeout'

    context 'when page content encoding is valid' do
      render_views

      it 'shows the edit page' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include(s_('Wiki|Edit Page'))
      end
    end
  end

  describe 'PATCH #update' do
    let(:new_title) { 'New title' }
    let(:new_content) { 'New content' }
    let(:id_param) { wiki_title }

    subject(:request) do
      patch(:update,
            params: routing_params.merge(
              id: id_param,
              wiki: { title: new_title, content: new_content }
            ))
    end

    it_behaves_like 'edit action'

    context 'when page content encoding is valid' do
      render_views

      it 'updates the page' do
        request

        wiki_page = wiki.list_pages(load_content: true).first

        expect(wiki_page.title).to eq new_title
        expect(wiki_page.content).to eq new_content
      end
    end

    context 'when user does not have edit permissions' do
      before do
        sign_out(:user)
      end

      it 'renders the empty state' do
        request

        expect(response).to render_template('shared/wikis/empty')
      end
    end
  end

  describe 'POST #create' do
    let(:new_title) { 'New title' }
    let(:new_content) { 'New content' }

    subject(:request) do
      post(:create,
            params: routing_params.merge(
              wiki: { title: new_title, content: new_content }
            ))
    end

    context 'when page is valid' do
      it 'creates the page' do
        expect do
          request
        end.to change { wiki.list_pages.size }.by 1

        wiki_page = wiki.find_page(new_title)

        expect(wiki_page.title).to eq new_title
        expect(wiki_page.content).to eq new_content
      end
    end

    context 'when page is not valid' do
      let(:new_title) { '' }

      it 'renders the edit state' do
        expect do
          request
        end.not_to change { wiki.list_pages.size }

        expect(response).to render_template('shared/wikis/edit')
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:id_param) { wiki_title }
    let(:delete_user) { user }

    subject(:request) do
      delete(:destroy,
            params: routing_params.merge(
              id: id_param
            ))
    end

    before do
      sign_in(delete_user)
    end

    context 'when page exists' do
      shared_examples 'deletes the page' do
        specify do
          expect do
            request
          end.to change { wiki.list_pages.size }.by(-1)
        end
      end

      it_behaves_like 'deletes the page'

      context 'but page cannot be deleted' do
        before do
          allow_next_instance_of(WikiPage) do |page|
            allow(page).to receive(:delete).and_return(false)
          end
        end

        it 'renders the edit state' do
          expect do
            request
          end.not_to change { wiki.list_pages.size }

          expect(response).to render_template('shared/wikis/edit')
          expect(assigns(:error)).to eq('Could not delete wiki page')
        end
      end

      context 'when user is a developer' do
        let(:delete_user) { other_user }

        before do
          container.add_developer(other_user)
        end

        it_behaves_like 'deletes the page'
      end

      context 'when user is a reporter' do
        let(:delete_user) { other_user }

        before do
          container.add_reporter(other_user)
        end

        it 'returns 404' do
          is_expected.to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when page does not exist' do
      let(:id_param) { 'nil' }

      it 'renders 404' do
        expect do
          request
        end.not_to change { wiki.list_pages.size }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#git_access' do
    render_views

    it 'renders the git access page' do
      get :git_access, params: routing_params

      expect(response).to render_template('shared/wikis/git_access')
      expect(response.body).to include(wiki.http_url_to_repo)
    end
  end

  def redirect_to_wiki(wiki, page)
    redirect_to(controller.wiki_page_path(wiki, page))
  end
end
