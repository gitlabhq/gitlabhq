# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::ExternalLinkFilter, feature_category: :markdown do
  include FilterSpecHelper

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
    exp = act = %(<a href="#{internal}/sign_in">Login</a>)
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
    it 'adds rel and target attributes to broken hrefs' do
      doc = filter %q(<p><a href="don't crash on broken urls">Google</a></p>)
      expected = %q(<p><a href="don't%20crash%20on%20broken%20urls" rel="nofollow noreferrer noopener" target="_blank">Google</a></p>)

      expect(doc.to_html).to eq(expected)
    end

    it 'adds rel and target to improperly formatted mailtos' do
      doc = filter %q(<p><a href="mailto://jblogs@example.com">Email</a></p>)
      expected = %q(<p><a href="mailto://jblogs@example.com" rel="nofollow noreferrer noopener" target="_blank">Email</a></p>)

      expect(doc.to_html).to eq(expected)
    end

    it 'adds rel and target to improperly formatted autolinks' do
      doc = filter %q(<p><a href="mailto://jblogs@example.com">mailto://jblogs@example.com</a></p>)
      expected = %q(<p><a href="mailto://jblogs@example.com" rel="nofollow noreferrer noopener" target="_blank">mailto://jblogs@example.com</a></p>)

      expect(doc.to_html).to eq(expected)
    end

    it 'adds rel and target attributes to improperly formatted protocols' do
      doc = filter %q(<p><a target="_blank" href="http:evil.com">Reverse Tabnabbing</a></p>)
      expected = %q(<p><a target="_blank" href="http:evil.com" rel="nofollow noreferrer noopener">Reverse Tabnabbing</a></p>)

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

      let(:doc) { filter %(<a href="https://#{internal}@example.com" target="_blank">Reverse Tabnabbing</a>) }

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
      act = %(<a href="#{url}">Login</a>)
      exp = %(<a href="#{internal_link}">Login</a>)
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

  context 'links with RTLO character' do
    # In rendered text this looks like "http://example.com/evilexe.mp3"
    let(:doc) { filter %(<a href="http://example.com/evil%E2%80%AE3pm.exe">http://example.com/evil\u202E3pm.exe</a>) }

    it_behaves_like 'an external link with rel attribute'

    it 'escapes RTLO in link text' do
      expected = %q(http://example.com/evil%E2%80%AE3pm.exe</a>)

      expect(doc.to_html).to include(expected)
    end

    it 'does not mangle the link text' do
      doc = filter %(<a href="http://example.com">One<span>and</span>\u202Eexe.mp3</a>)

      expect(doc.to_html).to include('One<span>and</span>%E2%80%AEexe.mp3</a>')
    end
  end

  context 'for generated autolinks' do
    context 'with an IDN character' do
      let(:doc)       { filter(%q(<a href="http://exa%F0%9F%98%84mple.com">http://exa😄mple.com</a>)) }
      let(:doc_email) { filter(%q(<a href="http://exa%F0%9F%98%84mple.com">http://exa😄mple.com</a>), emailable_links: true) }

      it_behaves_like 'an external link with rel attribute'

      it 'does not change the link text' do
        expect(doc.to_html).to include('http://exa😄mple.com</a>')
      end

      it 'uses punycode for emails' do
        expect(doc_email.to_html).to include('http://xn--example-6p25f.com/</a>')
      end
    end

    context 'autolinked image' do
      let(:html) { %q(<a href="https://assets.example.com/6d8b/634c" data-canonical-src="http://exa%F0%9F%98%84mple.com/test.png"><img src="http://exa%F0%9F%98%84mple.com/test.png" data-canonical-src="http://exa%F0%9F%98%84mple.com/test.png"></a>) }
      let(:doc)  { filter(html) }

      it_behaves_like 'an external link with rel attribute'

      it 'adds a toolip with punycode' do
        expect(doc.to_html).to include('class="has-tooltip"')
        expect(doc.to_html).to include('title="http://xn--example-6p25f.com/test.png"')
      end
    end
  end

  context 'for links that look malicious' do
    context 'with an IDN character' do
      let(:doc) { filter %q(<a href="http://exa%F0%9F%98%84mple.com">http://exa😄mple.com</a>) }

      it 'adds a toolip with punycode' do
        expect(doc.to_html).to include('http://exa😄mple.com</a>')
        expect(doc.to_html).to include('class="has-tooltip"')
        expect(doc.to_html).to include('title="http://xn--example-6p25f.com/"')
      end
    end

    context 'with RTLO character' do
      let(:doc) { filter %q(<a href="http://example.com/evil%E2%80%AE3pm.exe">Evil Test</a>) }

      it 'adds a toolip with punycode' do
        expect(doc.to_html).to include('Evil Test</a>')
        expect(doc.to_html).to include('class="has-tooltip"')
        expect(doc.to_html).to include('title="http://example.com/evil%E2%80%AE3pm.exe"')
      end
    end
  end

  context 'for links that have `rel=license`' do
    let(:doc) { filter %q(<a rel="license" href="http://example.com">rel-license</a>) }

    it_behaves_like 'an external link with rel attribute'

    it 'maintains rel license' do
      expect(doc.at_css('a')).to have_attribute('rel')
      expect(doc.at_css('a')['rel']).to include 'license'
    end
  end

  it_behaves_like 'does not use pipeline timing check'

  it_behaves_like 'a filter timeout' do
    let(:text) { 'text' }
    let(:expected_result) { Banzai::Filter::SanitizeLinkFilter::TIMEOUT_MARKDOWN_MESSAGE }
    let(:expected_timeout) { described_class::SANITIZATION_RENDER_TIMEOUT }
  end
end
