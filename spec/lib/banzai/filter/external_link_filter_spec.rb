require 'spec_helper'

shared_examples 'an external link with rel attribute' do
  it 'adds rel="nofollow" to external links' do
    expect(doc.at_css('a')).to have_attribute('rel')
    expect(doc.at_css('a')['rel']).to include 'nofollow'
  end

  it 'adds rel="noreferrer" to external links' do
    expect(doc.at_css('a')).to have_attribute('rel')
    expect(doc.at_css('a')['rel']).to include 'noreferrer'
  end

  it 'adds rel="noopener" to external links' do
    expect(doc.at_css('a')).to have_attribute('rel')
    expect(doc.at_css('a')['rel']).to include 'noopener'
  end
end

describe Banzai::Filter::ExternalLinkFilter do
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

    it_behaves_like 'an external link with rel attribute'
  end

  context 'for nested links on document' do
    let(:doc) { filter %q(<p><a href="https://google.com/">Google</a></p>) }

    it_behaves_like 'an external link with rel attribute'
  end

  context 'for invalid urls' do
    it 'skips broken hrefs' do
      doc = filter %q(<p><a href="don't crash on broken urls">Google</a></p>)
      expected = %q(<p><a href="don't%20crash%20on%20broken%20urls">Google</a></p>)

      expect(doc.to_html).to eq(expected)
    end

    it 'skips improperly formatted mailtos' do
      doc = filter %q(<p><a href="mailto://jblogs@example.com">Email</a></p>)
      expected = %q(<p><a href="mailto://jblogs@example.com">Email</a></p>)

      expect(doc.to_html).to eq(expected)
    end
  end

  context 'for links with a username' do
    context 'with a valid username' do
      let(:doc) { filter %q(<a href="https://user@google.com/">Google</a>) }

      it_behaves_like 'an external link with rel attribute'
    end

    context 'with an impersonated username' do
      let(:internal) { Gitlab.config.gitlab.url }

      let(:doc) { filter %Q(<a href="https://#{internal}@example.com" target="_blank">Reverse Tabnabbing</a>) }

      it_behaves_like 'an external link with rel attribute'
    end
  end

  context 'for non-lowercase scheme links' do
    context 'with http' do
      let(:doc) { filter %q(<p><a href="httP://google.com/">Google</a></p>) }

      it_behaves_like 'an external link with rel attribute'
    end

    context 'with https' do
      let(:doc) { filter %q(<p><a href="hTTpS://google.com/">Google</a></p>) }

      it_behaves_like 'an external link with rel attribute'
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

  context 'for protocol-relative links' do
    let(:doc) { filter %q(<p><a href="//google.com/">Google</a></p>) }

    it_behaves_like 'an external link with rel attribute'
  end
end
