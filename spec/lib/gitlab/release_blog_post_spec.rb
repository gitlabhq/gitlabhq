require 'spec_helper'

describe Gitlab::ReleaseBlogPost do
  describe '.blog_post_url' do
    let(:releases_xml) do
      <<~EOS
      <?xml version='1.0' encoding='utf-8' ?>
      <feed xmlns='http://www.w3.org/2005/Atom'>
      <entry>
      <release>11.2</release>
      <id>https://about.gitlab.com/2018/08/22/gitlab-11-2-released/</id>
      </entry>
      <entry>
      <release>11.1</release>
      <id>https://about.gitlab.com/2018/07/22/gitlab-11-1-released/</id>
      </entry>
      <entry>
      <release>11.0</release>
      <id>https://about.gitlab.com/2018/06/22/gitlab-11-0-released/</id>
      </entry>
      <entry>
      <release>10.8</release>
      <id>https://about.gitlab.com/2018/05/22/gitlab-10-8-released/</id>
      </entry>
      </feed>
      EOS
    end

    subject { described_class.send(:new).blog_post_url }

    before do
      stub_request(:get, 'https://about.gitlab.com/releases.xml')
        .to_return(status: 200, headers: { 'content-type' => ['text/xml'] }, body: releases_xml)
    end

    context 'matches GitLab version to blog post url' do
      it 'returns the correct url for major pre release' do
        stub_const('Gitlab::VERSION', '11.0.0-pre')

        expect(subject).to eql('https://about.gitlab.com/2018/05/22/gitlab-10-8-released/')
      end

      it 'returns the correct url for major release candidate' do
        stub_const('Gitlab::VERSION', '11.0.0-rc3')

        expect(subject).to eql('https://about.gitlab.com/2018/05/22/gitlab-10-8-released/')
      end

      it 'returns the correct url for major release' do
        stub_const('Gitlab::VERSION', '11.0.0')

        expect(subject).to eql('https://about.gitlab.com/2018/06/22/gitlab-11-0-released/')
      end

      it 'returns the correct url for minor pre release' do
        stub_const('Gitlab::VERSION', '11.2.0-pre')

        expect(subject).to eql('https://about.gitlab.com/2018/07/22/gitlab-11-1-released/')
      end

      it 'returns the correct url for minor release candidate' do
        stub_const('Gitlab::VERSION', '11.2.0-rc3')

        expect(subject).to eql('https://about.gitlab.com/2018/07/22/gitlab-11-1-released/')
      end

      it 'returns the correct url for minor release' do
        stub_const('Gitlab::VERSION', '11.2.0')

        expect(subject).to eql('https://about.gitlab.com/2018/08/22/gitlab-11-2-released/')
      end

      it 'returns the correct url for patch pre release' do
        stub_const('Gitlab::VERSION', '11.2.1-pre')
        expect(subject).to eql('https://about.gitlab.com/2018/08/22/gitlab-11-2-released/')
      end

      it 'returns the correct url for patch release candidate' do
        stub_const('Gitlab::VERSION', '11.2.1-rc3')

        expect(subject).to eql('https://about.gitlab.com/2018/08/22/gitlab-11-2-released/')
      end

      it 'returns the correct url for patch release' do
        stub_const('Gitlab::VERSION', '11.2.1')

        expect(subject).to eql('https://about.gitlab.com/2018/08/22/gitlab-11-2-released/')
      end

      it 'returns nil when no blog post is matched' do
        stub_const('Gitlab::VERSION', '9.0.0')

        expect(subject).to be(nil)
      end
    end
  end
end
