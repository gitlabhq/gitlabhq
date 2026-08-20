# frozen_string_literal: true

require 'spec_helper'

# Check end-to-end that a bare permalink in Markdown is rendered to a snippet card
# through the full + post-processing pipelines.
RSpec.describe 'Blob permalink embeds', :request_store, feature_category: :markdown do
  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:user) { project.first_owner }

  let(:sha) { project.commit.sha }
  let(:path) { 'files/ruby/popen.rb' }
  let(:anchor) { 'L3-6' }
  let(:permalink) { "#{Gitlab.config.gitlab.url}/#{project.full_path}/-/blob/#{sha}/#{path}##{anchor}" }

  def render(markdown)
    html = Banzai.render_and_post_process(markdown, project: project, current_user: user)
    Nokogiri::HTML5.fragment(html)
  end

  it 'expands a bare permalink pasted on its own line into a snippet card' do
    result = render("Look at this:\n\n#{permalink}\n")

    embed = result.at_css('.blob-embed')
    expect(embed).to be_present
    expect(embed.at_css('.blob-embed-title')['href']).to eq(permalink)
  end

  it 'expands a permalink that carries a query string' do
    url = "#{Gitlab.config.gitlab.url}/#{project.full_path}/-/blob/#{sha}/#{path}?blame=1&page=2##{anchor}"

    result = render("#{url}\n")

    expect(result.at_css('.blob-embed')).to be_present
  end

  it 'leaves a permalink used inline within a sentence as a plain link' do
    result = render("See #{permalink} for details.")

    expect(result.at_css('.blob-embed')).to be_nil
    expect(result.at_css('a')['href']).to eq(permalink)
  end

  it 'leaves a permalink the author gave their own link text alone' do
    result = render("[see this bit](#{permalink})\n")

    expect(result.at_css('.blob-embed')).to be_nil
    expect(result.at_css('a').text).to eq('see this bit')
  end
end
