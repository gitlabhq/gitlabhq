# frozen_string_literal: true

RSpec.shared_examples 'wiki controller actions' do
  let(:container) { raise NotImplementedError }
  let(:routing_params) { raise NotImplementedError }

  let_it_be(:user) { create(:user) }
  let(:wiki) { Wiki.for_container(container, user) }
  let(:wiki_title) { 'page title test' }

  before do
    create(:wiki_page, wiki: wiki, title: wiki_title, content: 'hello world')

    sign_in(user)
  end

  describe 'GET #new' do
    subject { get :new, params: routing_params }

    it 'redirects to #show and appends a `random_title` param' do
      subject

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
        subject

        expect(response).to redirect_to(container)
        expect(flash[:notice]).to eq('Could not create Wiki Repository at this time. Please try again later.')
      end
    end
  end

  describe 'GET #pages' do
    before do
      get :pages, params: routing_params.merge(id: wiki_title)
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

    it_behaves_like 'fetching history', :ok do
      let(:allow_read_wiki)   { true }

      it 'assigns @page_versions' do
        expect(assigns(:page_versions)).to be_present
      end
    end

    it_behaves_like 'fetching history', :not_found do
      let(:allow_read_wiki)   { false }
    end
  end

  describe 'GET #show' do
    render_views

    let(:random_title) { nil }

    subject { get :show, params: routing_params.merge(id: id, random_title: random_title) }

    context 'when page exists' do
      let(:id) { wiki_title }

      it 'renders the page' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:page).title).to eq(wiki_title)
        expect(assigns(:sidebar_wiki_entries)).to contain_exactly(an_instance_of(WikiPage))
        expect(assigns(:sidebar_limited)).to be(false)
      end

      context 'when page content encoding is invalid' do
        it 'sets flash error' do
          allow(controller).to receive(:valid_encoding?).and_return(false)

          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(flash[:notice]).to eq(_('The content of this page is not encoded in UTF-8. Edits can only be made via the Git repository.'))
        end
      end
    end

    context 'when the page does not exist' do
      let(:id) { 'does not exist' }

      before do
        subject
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

    context 'when page is a file' do
      include WikiHelpers

      let(:id) { upload_file_to_wiki(container, user, file_name) }

      context 'when file is an image' do
        let(:file_name) { 'dk.png' }

        it 'delivers the image' do
          subject

          expect(response.headers['Content-Disposition']).to match(/^inline/)
          expect(response.headers[Gitlab::Workhorse::DETECT_HEADER]).to eq "true"
        end

        context 'when file is a svg' do
          let(:file_name) { 'unsanitized.svg' }

          it 'delivers the image' do
            subject

            expect(response.headers['Content-Disposition']).to match(/^inline/)
            expect(response.headers[Gitlab::Workhorse::DETECT_HEADER]).to eq "true"
          end
        end

        it_behaves_like 'project cache control headers' do
          let(:project) { container }
        end
      end

      context 'when file is a pdf' do
        let(:file_name) { 'git-cheat-sheet.pdf' }

        it 'sets the content type to sets the content response headers' do
          subject

          expect(response.headers['Content-Disposition']).to match(/^inline/)
          expect(response.headers[Gitlab::Workhorse::DETECT_HEADER]).to eq "true"
        end

        it_behaves_like 'project cache control headers' do
          let(:project) { container }
        end
      end
    end
  end

  describe 'POST #preview_markdown' do
    it 'renders json in a correct format' do
      post :preview_markdown, params: routing_params.merge(id: 'page/path', text: '*Markdown* text')

      expect(json_response.keys).to match_array(%w(body references))
    end
  end

  describe 'GET #edit' do
    subject { get(:edit, params: routing_params.merge(id: wiki_title)) }

    context 'when page content encoding is invalid' do
      it 'redirects to show' do
        allow(controller).to receive(:valid_encoding?).and_return(false)

        subject

        expect(response).to redirect_to_wiki(wiki, wiki.list_pages.first)
      end
    end

    context 'when the page has nil content' do
      let(:page) { create(:wiki_page) }

      it 'redirects to show' do
        allow(page).to receive(:content).and_return(nil)
        allow(controller).to receive(:page).and_return(page)

        subject

        expect(response).to redirect_to_wiki(wiki, page)
      end
    end

    context 'when page content encoding is valid' do
      render_views

      it 'shows the edit page' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include(s_('Wiki|Edit Page'))
      end
    end
  end

  describe 'PATCH #update' do
    let(:new_title) { 'New title' }
    let(:new_content) { 'New content' }

    subject do
      patch(:update,
            params: routing_params.merge(
              id: wiki_title,
              wiki: { title: new_title, content: new_content }
            ))
    end

    context 'when page content encoding is invalid' do
      it 'redirects to show' do
        allow(controller).to receive(:valid_encoding?).and_return(false)

        subject
        expect(response).to redirect_to_wiki(wiki, wiki.list_pages.first)
      end
    end

    context 'when page content encoding is valid' do
      render_views

      it 'updates the page' do
        subject

        wiki_page = wiki.list_pages(load_content: true).first

        expect(wiki_page.title).to eq new_title
        expect(wiki_page.content).to eq new_content
      end
    end
  end

  def redirect_to_wiki(wiki, page)
    redirect_to(controller.wiki_page_path(wiki, page))
  end
end
