# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::RepositoryBlobEmbedFilter, :request_store, feature_category: :markdown do
  include FilterSpecHelper

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:user) { create(:user) }

  let(:current_user) { user }
  let(:sha) { project.commit.sha }
  let(:path) { 'files/ruby/popen.rb' }
  let(:anchor) { 'L3-6' }
  let(:full_path) { project.full_path }

  def blob_url(
    host: Gitlab.config.gitlab.url, path_project: full_path, blob_sha: sha, blob_path: path,
    query: '', fragment: anchor)
    "#{host}/#{path_project}/-/blob/#{blob_sha}/#{blob_path}#{query}##{fragment}"
  end

  # A bare URL rendered as an autolink: the link's text is its href.
  def standalone_paragraph(url)
    paragraph_with('<p><a></a></p>', url, url)
  end

  def inline_paragraph(url)
    paragraph_with('<p>see <a></a></p>', url, url)
  end

  def titled_paragraph(url, text)
    paragraph_with('<p><a></a></p>', url, text)
  end

  def paragraph_with(html, url, text)
    fragment = Nokogiri::HTML5.fragment(html)
    link = fragment.at_css('a')
    link['href'] = url
    link.content = text
    fragment.to_html
  end

  def filter_html(html)
    filter(html, current_user: current_user)
  end

  def embed_paragraphs(count)
    Array.new(count) { |i| standalone_paragraph(blob_url(fragment: "L#{i + 1}-#{i + 2}")) }.join
  end

  it 'embeds a standalone full-SHA1 permalink as a highlighted snippet', :aggregate_failures do
    result = filter_html(standalone_paragraph(blob_url))

    embed = result.at_css('.blob-embed')
    expect(embed).to be_present
    expect(embed.at_css('.blob-embed-title').text).to eq(path)
  end

  it 'embeds a permalink with a query string' do
    result = filter_html(standalone_paragraph(blob_url(query: '?blame=1&page=2')))

    expect(result.at_css('.blob-embed')).to be_present
  end

  it 'does not embed a link that is not the sole content of its paragraph', :aggregate_failures do
    result = filter_html(inline_paragraph(blob_url))

    expect(result.at_css('.blob-embed')).to be_nil
    expect(result.at_css('a')['href']).to eq(blob_url)
  end

  it 'does not embed a link the author gave their own text', :aggregate_failures do
    result = filter_html(titled_paragraph(blob_url, 'see this bit'))

    expect(result.at_css('.blob-embed')).to be_nil
    expect(result.at_css('a').text).to eq('see this bit')
  end

  it 'does not embed a branch-ref blob link', :aggregate_failures do
    url = blob_url(blob_sha: 'master')

    result = filter_html(standalone_paragraph(url))

    expect(result.at_css('.blob-embed')).to be_nil
    expect(result.at_css('a')['href']).to eq(url)
  end

  it 'does not embed a blob link with no line anchor' do
    url = blob_url(fragment: '')

    result = filter_html(standalone_paragraph(url.chomp('#')))

    expect(result.at_css('.blob-embed')).to be_nil
  end

  it 'does not embed a link to another instance', :aggregate_failures do
    url = blob_url(host: 'https://example.com')

    result = filter_html(standalone_paragraph(url))

    expect(result.at_css('.blob-embed')).to be_nil
    expect(result.at_css('a')['href']).to eq(url)
  end

  it 'leaves the link untouched when the blob does not exist at that commit', :aggregate_failures do
    url = blob_url(blob_path: 'does/not/exist.rb')

    result = filter_html(standalone_paragraph(url))

    expect(result.at_css('.blob-embed')).to be_nil
    expect(result.at_css('a')['href']).to eq(url)
  end

  it 'leaves the link untouched when the project does not exist', :aggregate_failures do
    url = blob_url(path_project: 'no/such-project')

    result = filter_html(standalone_paragraph(url))

    expect(result.at_css('.blob-embed')).to be_nil
    expect(result.at_css('a')['href']).to eq(url)
  end

  context 'with a permalink to another project' do
    let_it_be(:other_project) { create(:project, :repository, :public) }

    let(:full_path) { other_project.full_path }
    let(:sha) { other_project.commit.sha }

    it 'embeds when the viewer can read the target project, qualifying the title with its full path',
      :aggregate_failures do
      result = filter_html(standalone_paragraph(blob_url))

      embed = result.at_css('.blob-embed')
      expect(embed).to be_present
      expect(embed.at_css('.blob-embed-title').text).to eq("#{other_project.full_path}/#{path}")
    end

    context 'when the target project is private and the viewer has no access' do
      let_it_be(:other_project) { create(:project, :repository, :private) }

      it 'leaves the link untouched', :aggregate_failures do
        result = filter_html(standalone_paragraph(blob_url))

        expect(result.at_css('.blob-embed')).to be_nil
        expect(result.at_css('a')['href']).to eq(blob_url)
      end
    end

    context 'when the viewer may not read across projects' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :read_cross_project).and_return(false)
      end

      it 'leaves the link untouched', :aggregate_failures do
        result = filter_html(standalone_paragraph(blob_url))

        expect(result.at_css('.blob-embed')).to be_nil
        expect(result.at_css('a')['href']).to eq(blob_url)
      end

      it "still embeds a permalink to the document's own project" do
        url = blob_url(path_project: project.full_path, blob_sha: project.commit.sha)

        result = filter_html(standalone_paragraph(url))

        expect(result.at_css('.blob-embed')).to be_present
      end
    end
  end

  context 'with permalinks into several projects' do
    let_it_be(:targets) { create_list(:project, 3, :repository, :public) }

    def target_paragraphs(projects)
      projects.map do |target|
        standalone_paragraph(blob_url(path_project: target.full_path, blob_sha: target.commit.sha))
      end.join
    end

    # Each run starts from a cold store so that warming from the previous run
    # cannot mask a per-project query.
    shared_examples 'a constant number of queries' do
      it 'does not issue more queries as more projects are referenced' do
        filter_html(target_paragraphs(targets)) # warm what is shared between runs

        control = ActiveRecord::QueryRecorder.new do
          Gitlab::SafeRequestStore.clear!
          filter_html(target_paragraphs(targets.first(1)))
        end

        expect do
          Gitlab::SafeRequestStore.clear!
          filter_html(target_paragraphs(targets))
        end.not_to exceed_query_limit(control)
      end
    end

    it_behaves_like 'a constant number of queries'

    context 'when the targets are private and the viewer is a member' do
      let_it_be(:targets) do
        create_list(:project, 3, :repository, :private).each { |target| target.add_developer(user) }
      end

      it 'embeds every one of them' do
        result = filter_html(target_paragraphs(targets))

        expect(result.css('.blob-embed').size).to eq(targets.size)
      end

      it_behaves_like 'a constant number of queries'
    end
  end

  it 'batches blob reads for multiple embeds into a single repository call', :aggregate_failures do
    # Resolve every path to this spec's own project, so that the repository the
    # filter reads through is the instance asserted on below.
    relation = Project.id_in(project.id)
    allow(relation).to receive(:preload).and_return([project])
    allow(Project).to receive(:where_full_path_in).and_return(relation)

    paragraphs = %w[files/ruby/popen.rb files/ruby/regex.rb README.md]
      .map { |p| standalone_paragraph(blob_url(blob_path: p)) }.join

    expect(project.repository).to receive(:blobs_at).once.and_call_original
    expect(project.repository).not_to receive(:blob_at)

    filter_html(paragraphs)
  end

  it 'stops embedding after EMBED_LIMIT links' do
    result = filter_html(embed_paragraphs(described_class::EMBED_LIMIT + 2))

    expect(result.css('.blob-embed').size).to eq(described_class::EMBED_LIMIT)
  end

  it 'stops parsing after CANDIDATE_LIMIT links, however few are embeddable' do
    paragraphs = Array.new(described_class::CANDIDATE_LIMIT + 5) do |i|
      standalone_paragraph(blob_url(path_project: "no/such-project-#{i}"))
    end.join

    expect(Project).to receive(:where_full_path_in)
      .with(have_attributes(size: described_class::CANDIDATE_LIMIT)).and_return(Project.none)

    filter_html(paragraphs)
  end

  context 'when the feature flag is disabled' do
    before do
      stub_feature_flags(blob_permalink_embed: false)
    end

    it 'leaves the link untouched', :aggregate_failures do
      result = filter_html(standalone_paragraph(blob_url))

      expect(result.at_css('.blob-embed')).to be_nil
      expect(result.at_css('a')['href']).to eq(blob_url)
    end
  end
end
