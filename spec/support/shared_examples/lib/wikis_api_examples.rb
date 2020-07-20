# frozen_string_literal: true

RSpec.shared_examples_for 'wikis API returns list of wiki pages' do
  context 'when wiki has pages' do
    let!(:pages) do
      [create(:wiki_page, wiki: wiki, title: 'page1', content: 'content of page1'),
       create(:wiki_page, wiki: wiki, title: 'page2.with.dot', content: 'content of page2')]
    end

    it 'returns the list of wiki pages without content' do
      get api(url, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.size).to eq(2)

      json_response.each_with_index do |page, index|
        expect(page.keys).to match_array(expected_keys_without_content)
        expect(page['slug']).to eq(pages[index].slug)
        expect(page['title']).to eq(pages[index].title)
      end
    end

    it 'returns the list of wiki pages with content' do
      get api(url, user), params: { with_content: 1 }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.size).to eq(2)

      json_response.each_with_index do |page, index|
        expect(page.keys).to match_array(expected_keys_with_content)
        expect(page['content']).to eq(pages[index].content)
        expect(page['slug']).to eq(pages[index].slug)
        expect(page['title']).to eq(pages[index].title)
      end
    end
  end

  it 'return the empty list of wiki pages' do
    get api(url, user)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.size).to eq(0)
  end
end

RSpec.shared_examples_for 'wikis API returns wiki page' do
  it 'returns the wiki page' do
    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.size).to eq(4)
    expect(json_response.keys).to match_array(expected_keys_with_content)
    expect(json_response['content']).to eq(page.content)
    expect(json_response['slug']).to eq(page.slug)
    expect(json_response['title']).to eq(page.title)
  end
end

RSpec.shared_examples_for 'wikis API creates wiki page' do
  it 'creates the wiki page' do
    post(api(url, user), params: payload)

    expect(response).to have_gitlab_http_status(:created)
    expect(json_response.size).to eq(4)
    expect(json_response.keys).to match_array(expected_keys_with_content)
    expect(json_response['content']).to eq(payload[:content])
    expect(json_response['slug']).to eq(payload[:title].tr(' ', '-'))
    expect(json_response['title']).to eq(payload[:title])
    expect(json_response['rdoc']).to eq(payload[:rdoc])
  end

  [:title, :content].each do |part|
    it "responds with validation error on empty #{part}" do
      payload.delete(part)

      post(api(url, user), params: payload)

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response.size).to eq(1)
      expect(json_response['error']).to eq("#{part} is missing")
    end
  end
end

RSpec.shared_examples_for 'wikis API updates wiki page' do
  it 'updates the wiki page' do
    put(api(url, user), params: payload)

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.size).to eq(4)
    expect(json_response.keys).to match_array(expected_keys_with_content)
    expect(json_response['content']).to eq(payload[:content])
    expect(json_response['slug']).to eq(payload[:title].tr(' ', '-'))
    expect(json_response['title']).to eq(payload[:title])
  end

  [:title, :content, :format].each do |part|
    it "updates with wiki with missing #{part}" do
      payload.delete(part)

      put(api(url, user), params: payload)

      expect(response).to have_gitlab_http_status(:ok)
    end
  end
end

RSpec.shared_examples_for 'wiki API 403 Forbidden' do
  it 'returns 403 Forbidden' do
    expect(response).to have_gitlab_http_status(:forbidden)
    expect(json_response.size).to eq(1)
    expect(json_response['message']).to eq('403 Forbidden')
  end
end

RSpec.shared_examples_for 'wiki API 404 Wiki Page Not Found' do
  it 'returns 404 Wiki Page Not Found' do
    expect(response).to have_gitlab_http_status(:not_found)
    expect(json_response.size).to eq(1)
    expect(json_response['message']).to eq('404 Wiki Page Not Found')
  end
end

RSpec.shared_examples_for 'wiki API 404 Not Found' do |what|
  it "returns 404 #{what} Not Found" do
    expect(response).to have_gitlab_http_status(:not_found)
    expect(json_response.size).to eq(1)
    expect(json_response['message']).to eq("404 #{what} Not Found")
  end
end

RSpec.shared_examples_for 'wiki API 204 No Content' do
  it 'returns 204 No Content' do
    expect(response).to have_gitlab_http_status(:no_content)
  end
end

RSpec.shared_examples_for 'wiki API uploads wiki attachment' do
  it 'pushes attachment to the wiki repository' do
    allow(SecureRandom).to receive(:hex).and_return('fixed_hex')

    workhorse_post_with_file(api(url, user), file_key: :file, params: payload)

    expect(response).to have_gitlab_http_status(:created)
    expect(json_response).to eq result_hash.deep_stringify_keys
  end

  it 'responds with validation error on empty file' do
    payload.delete(:file)

    post(api(url, user), params: payload)

    expect(response).to have_gitlab_http_status(:bad_request)
    expect(json_response.size).to eq(1)
    expect(json_response['error']).to eq('file is missing')
  end

  it 'responds with validation error on invalid temp file' do
    payload[:file] = { tempfile: '/etc/hosts' }

    post(api(url, user), params: payload)

    expect(response).to have_gitlab_http_status(:bad_request)
    expect(json_response.size).to eq(1)
    expect(json_response['error']).to eq('file is invalid')
  end

  it 'is backward compatible with regular multipart uploads' do
    allow(SecureRandom).to receive(:hex).and_return('fixed_hex')

    post(api(url, user), params: payload)

    expect(response).to have_gitlab_http_status(:created)
    expect(json_response).to eq result_hash.deep_stringify_keys
  end
end
