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

  it 'adds rel="nofollow" to external links' do
    act = %q(<a href="https://google.com/">Google</a>)
    doc = filter(act)

    expect(doc.at_css('a')).to have_attribute('rel')
    expect(doc.at_css('a')['rel']).to eq 'nofollow'
  end
end
