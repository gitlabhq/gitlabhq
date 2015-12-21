require 'spec_helper'

describe Banzai::Filter::AutolinkFilter, lib: true do
  include FilterSpecHelper

  let(:link) { 'http://about.gitlab.com/' }

  it 'does nothing when :autolink is false' do
    exp = act = link
    expect(filter(act, autolink: false).to_html).to eq exp
  end

  it 'does nothing with non-link text' do
    exp = act = 'This text contains no links to autolink'
    expect(filter(act).to_html).to eq exp
  end

  context 'Rinku schemes' do
    it 'autolinks http' do
      doc = filter("See #{link}")
      expect(doc.at_css('a').text).to eq link
      expect(doc.at_css('a')['href']).to eq link
    end

    it 'autolinks https' do
      link = 'https://google.com/'
      doc = filter("See #{link}")

      expect(doc.at_css('a').text).to eq link
      expect(doc.at_css('a')['href']).to eq link
    end

    it 'autolinks ftp' do
      link = 'ftp://ftp.us.debian.org/debian/'
      doc = filter("See #{link}")

      expect(doc.at_css('a').text).to eq link
      expect(doc.at_css('a')['href']).to eq link
    end

    it 'autolinks short URLs' do
      link = 'http://localhost:3000/'
      doc = filter("See #{link}")

      expect(doc.at_css('a').text).to eq link
      expect(doc.at_css('a')['href']).to eq link
    end

    it 'accepts link_attr options' do
      doc = filter("See #{link}", link_attr: { class: 'custom' })

      expect(doc.at_css('a')['class']).to eq 'custom'
    end

    described_class::IGNORE_PARENTS.each do |elem|
      it "ignores valid links contained inside '#{elem}' element" do
        exp = act = "<#{elem}>See #{link}</#{elem}>"
        expect(filter(act).to_html).to eq exp
      end
    end
  end

  context 'other schemes' do
    let(:link) { 'foo://bar.baz/' }

    it 'autolinks smb' do
      link = 'smb:///Volumes/shared/foo.pdf'
      doc = filter("See #{link}")

      expect(doc.at_css('a').text).to eq link
      expect(doc.at_css('a')['href']).to eq link
    end

    it 'autolinks irc' do
      link = 'irc://irc.freenode.net/git'
      doc = filter("See #{link}")

      expect(doc.at_css('a').text).to eq link
      expect(doc.at_css('a')['href']).to eq link
    end

    it 'does not include trailing punctuation' do
      doc = filter("See #{link}.")
      expect(doc.at_css('a').text).to eq link

      doc = filter("See #{link}, ok?")
      expect(doc.at_css('a').text).to eq link

      doc = filter("See #{link}...")
      expect(doc.at_css('a').text).to eq link
    end

    it 'does not include trailing HTML entities' do
      doc = filter("See &lt;&lt;&lt;#{link}&gt;&gt;&gt;")

      expect(doc.at_css('a')['href']).to eq link
      expect(doc.text).to eq "See <<<#{link}>>>"
    end

    it 'accepts link_attr options' do
      doc = filter("See #{link}", link_attr: { class: 'custom' })
      expect(doc.at_css('a')['class']).to eq 'custom'
    end

    described_class::IGNORE_PARENTS.each do |elem|
      it "ignores valid links contained inside '#{elem}' element" do
        exp = act = "<#{elem}>See #{link}</#{elem}>"
        expect(filter(act).to_html).to eq exp
      end
    end
  end
end
