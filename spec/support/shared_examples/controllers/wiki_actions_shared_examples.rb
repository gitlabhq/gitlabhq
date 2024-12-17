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

  shared_examples 'recovers from git errors' do
    let(:method_name) { :page }

    context 'when we encounter CommandTimedOut error' do
      it 'renders the appropriate template', :aggregate_failures do
        expect(controller)
          .to receive(method_name)
          .and_raise(::Gitlab::Git::CommandTimedOut, 'Deadline Exceeded')

        request

        expect(response).to render_template('shared/wikis/git_error')
      end
    end

    context 'when we encounter a NoRepository error' do
      it 'renders the appropriate template', :aggregate_failures do
        expect(controller)
          .to receive(method_name)
          .and_raise(Gitlab::Git::Repository::NoRepository)

        request

        expect(response).to render_template('shared/wikis/empty')
        expect(assigns(:error)).to eq('Could not access the Wiki Repository at this time.')
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
        expect(wiki).to receive(:create_wiki_repository) { raise Wiki::CouldNotCreateWikiError }
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

    it_behaves_like 'recovers from git errors' do
      subject(:request) { get :pages, params: routing_params.merge(id: wiki_title) }

      let(:method_name) { :pages_list }
    end

    it 'assigns the page collections' do
      expect(assigns(:pages_list)).to contain_exactly(an_instance_of(WikiPage))
      expect(assigns(:wiki_entries)).to contain_exactly(an_instance_of(WikiPage))
    end

    it 'does not load the page content' do
      expect(assigns(:page)).to be_nil
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

    it_behaves_like 'recovers from git errors' do
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
        expect(assigns(:page).content).to be_empty
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

    it_behaves_like 'recovers from git errors' do
      subject(:request) { get :diff, params: routing_params.merge(id: wiki_title, version_id: wiki.repository.commit.id) }
    end
  end

  describe 'GET #show' do
    render_views

    let(:random_title) { nil }

    subject(:request) { get :show, params: routing_params.merge(id: id, random_title: random_title) }

    context 'when page exists' do
      let(:id) { wiki_title }

      it_behaves_like 'recovers from git errors'

      it 'renders the page' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('shared/wikis/show')
        expect(assigns(:page).title).to eq(wiki_title)
      end

      context 'page view tracking' do
        it_behaves_like 'internal event tracking' do
          let(:event) { 'view_wiki_page' }
          let(:project) { container if container.is_a?(Project) }
          let(:namespace) { container.is_a?(Group) ? container : container.namespace }

          subject(:track_event) { request }
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
      end

      context 'when the user cannot create pages' do
        before do
          sign_out(:user)
        end

        it 'shows the empty state' do
          request

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response).to render_template('shared/wikis/404')
        end
      end
    end

    context 'when page is a file' do
      include WikiHelpers

      where(:file_name) { ['dk.png', 'unsanitized.svg', 'sample.pdf'] }

      with_them do
        let(:id) { upload_file_to_wiki(wiki, user, file_name) }

        it 'delivers the file with the correct headers' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers['Content-Disposition']).to match(/^inline/)
          expect(response.headers[Gitlab::Workhorse::DETECT_HEADER]).to eq('true')
          expect(response.cache_control[:public]).to be(false)
          expect(response.headers['Cache-Control']).to eq('max-age=60, private, must-revalidate, stale-while-revalidate=60, stale-if-error=300, s-maxage=60')
        end
      end
    end

    context 'when the page redirects to another page' do
      before do
        redirect_limit_yml = ''
        51.times do |i|
          redirect_limit_yml += "Page#{i}: Page#{i + 1}\n"
        end

        wiki.repository.update_file(
          user,
          '.gitlab/redirects.yml',
          "PageA: PageB\nLoopA: LoopB\nLoopB: LoopA\n#{redirect_limit_yml}",
          message: 'Create redirects file',
          branch_name: 'master'
        )
      end

      context 'that exists' do
        let(:id) { 'PageA' }

        before do
          create(:wiki_page, wiki: wiki, title: 'PageB', content: 'Page B content')
        end

        it 'redirects to the target page' do
          request

          expect(response).to redirect_to_wiki(wiki, 'PageB', redirected_from: 'PageA')
          expect(flash[:notice]).to eq('The page at <code>PageA</code> has been moved to <code>PageB</code>.')
        end
      end

      context 'that results in a redirect loop' do
        let(:id) { 'LoopA' }

        it 'renders the edit page with a notice' do
          request

          expect(response).to redirect_to_wiki(wiki, 'LoopA', redirect_limit_reached: true)
          expect(flash[:notice]).to eq('The page at <code>LoopA</code> redirected too many times. You are now editing the page at <code>LoopA</code>.')
        end
      end

      context 'that results in a redirect limit' do
        let(:id) { 'Page0' }

        it 'renders the edit page with a notice' do
          request

          expect(response).to redirect_to_wiki(wiki, 'Page0', redirect_limit_reached: true)
          expect(flash[:notice]).to eq('The page at <code>Page0</code> redirected too many times. You are now editing the page at <code>Page0</code>.')
        end
      end

      context 'but the original page also exists' do
        let(:id) { 'PageA' }

        before do
          create(:wiki_page, wiki: wiki, title: 'PageA', content: 'Page A content')
        end

        it 'renders the page instead of redirecting' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('shared/wikis/show')
          expect(assigns(:page).title).to eq('PageA')
        end
      end

      context 'when the destination page does not exist' do
        let(:redirected_from) { 'PageA' }
        let(:id) { 'PageB' }

        render_views

        before do
          routing_params[:redirected_from] = redirected_from
        end

        it 'renders the edit page for redirect with a notice and a link to edit the original page' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('shared/wikis/edit')

          expect(response.body).to include("The page at <code>PageA</code> tried to redirect to <code>PageB</code>, but it does not exist. You are now editing the page at <code>PageB</code>. <a href=\"#{controller.wiki_page_path(wiki, 'PageA')}?no_redirect=true\">Edit page at <code>PageA</code> instead.</a>")

          expect(flash[:notice]).to be_nil
        end
      end
    end
  end

  describe 'POST #preview_markdown' do
    let(:text) { '*Markdown* text' }

    it 'renders json in a correct format' do
      wiki_page = wiki.list_pages(load_content: true).first

      expect(Markup::RenderingService).to receive(:new)
        .with(text,
          context: hash_including(
            pipeline: :wiki,
            wiki: wiki,
            page_slug: wiki_page.slug,
            repository: wiki.repository,
            requested_path: wiki_page.path,
            issuable_reference_expansion_enabled: true
          ),
          postprocess_context: anything)
        .and_call_original

      post :preview_markdown, params: routing_params.merge(id: wiki_page.slug, text: text)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.keys).to match_array(%w[body references])
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
    it_behaves_like 'recovers from git errors'

    context 'when page content encoding is valid' do
      render_views

      it 'shows the edit page' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include('Edit · page title test')
      end
    end
  end

  describe 'PATCH #update' do
    let(:new_title) { 'New title' }
    let(:new_content) { 'New content' }
    let(:id_param) { wiki_title }

    subject(:request) do
      patch(:update, params: routing_params.merge(
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
      post(:create, params: routing_params.merge(
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
      delete(:destroy, params: routing_params.merge(
        id: id_param
      ))
    end

    before do
      sign_in(delete_user)
    end

    context 'when page exists' do
      shared_examples 'deletes the page' do
        specify do
          aggregate_failures do
            expect do
              request
            end.to change { wiki.list_pages.size }.by(-1)

            expect(assigns(:page).content).to be_empty
          end
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

  def redirect_to_wiki(wiki, page, query_params = {})
    query = query_params.empty? ? '' : "?#{query_params.to_query}"
    redirect_to("#{controller.wiki_page_path(wiki, page)}#{query}")
  end
end
