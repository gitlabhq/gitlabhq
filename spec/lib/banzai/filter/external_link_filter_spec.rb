require 'spec_helper'

describe Banzai::Filter::ExternalLinkFilter, lib: true do
  include FilterSpecHelper

  it 'ignores elements without an href attribute' do
    exp = act = %q(<a id="ignored">Ignore Me</a>)
    expect(filter(act).to_html).to eq exp
  end

  it 'ignores non-HTTP(S) links' do
    exp = act = %q(<a href="irc://irc.freenode.net/gitlab">IRC</a>)
    expect(filter(act).to_html).to eq exp
  end

  it 'skips internal links' do
    internal = Gitlab.config.gitlab.url
    exp = act = %Q(<a href="#{internal}/sign_in">Login</a>)
    expect(filter(act).to_html).to eq exp
  end

  context 'for root links on document' do
    let(:doc) { filter %q(<a href="https://google.com/">Google</a>) }

    it 'adds rel="nofollow" to external links' do
      expect(doc.at_css('a')).to have_attribute('rel')
      expect(doc.at_css('a')['rel']).to include 'nofollow'
    end

    it 'adds rel="noreferrer" to external links' do
      expect(doc.at_css('a')).to have_attribute('rel')
      expect(doc.at_css('a')['rel']).to include 'noreferrer'
    end
  end

  context 'for nested links on document' do
    let(:doc) { filter %q(<p><a href="https://google.com/">Google</a></p>) }

    it 'adds rel="nofollow" to external links' do
      expect(doc.at_css('a')).to have_attribute('rel')
      expect(doc.at_css('a')['rel']).to include 'nofollow'
    end

    it 'adds rel="noreferrer" to external links' do
      expect(doc.at_css('a')).to have_attribute('rel')
      expect(doc.at_css('a')['rel']).to include 'noreferrer'
    end
  end

  context 'for non-lowercase scheme links' do
    let(:doc_with_http) { filter %q(<p><a href="httP://google.com/">Google</a></p>) }
    let(:doc_with_https) { filter %q(<p><a href="hTTpS://google.com/">Google</a></p>) }

    it 'adds rel="nofollow" to external links' do
      expect(doc_with_http.at_css('a')).to have_attribute('rel')
      expect(doc_with_https.at_css('a')).to have_attribute('rel')

      expect(doc_with_http.at_css('a')['rel']).to include 'nofollow'
      expect(doc_with_https.at_css('a')['rel']).to include 'nofollow'
    end

    it 'adds rel="noreferrer" to external links' do
      expect(doc_with_http.at_css('a')).to have_attribute('rel')
      expect(doc_with_https.at_css('a')).to have_attribute('rel')

      expect(doc_with_http.at_css('a')['rel']).to include 'noreferrer'
      expect(doc_with_https.at_css('a')['rel']).to include 'noreferrer'
    end

    it 'skips internal links' do
      internal_link = Gitlab.config.gitlab.url + "/sign_in"
      url = internal_link.gsub(/\Ahttp/, 'HtTp')
      act = %Q(<a href="#{url}">Login</a>)
      exp = %Q(<a href="#{internal_link}">Login</a>)
      expect(filter(act).to_html).to eq(exp)
    end

    it 'skips relative links' do
      exp = act = %q(<a href="http_spec/foo.rb">Relative URL</a>)
      expect(filter(act).to_html).to eq(exp)
    end
  end
end
