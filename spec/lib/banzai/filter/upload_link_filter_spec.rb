# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::UploadLinkFilter do
  def filter(doc, contexts = {})
    contexts.reverse_merge!(
      project: project,
      group: group,
      only_path: only_path
    )

    described_class.call(doc, contexts)
  end

  def image(path)
    %(<img src="#{path}" />)
  end

  def video(path)
    %(<video src="#{path}"></video>)
  end

  def audio(path)
    %(<audio src="#{path}"></audio>)
  end

  def link(path)
    %(<a href="#{path}">#{path}</a>)
  end

  def nested(element)
    %(<div>#{element}</div>)
  end

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }

  let(:group) { nil }
  let(:project_path) { project.full_path }
  let(:only_path) { true }
  let(:upload_path) { '/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg' }
  let(:relative_path) { "/#{project.full_path}#{upload_path}" }

  it 'preserves original url in data-canonical-src attribute' do
    doc = filter(link(upload_path))

    expect(doc.at_css('a')['data-canonical-src']).to eq(upload_path)
  end

  context 'to a project upload' do
    context 'with an absolute URL' do
      let(:absolute_path) { Gitlab.config.gitlab.url + relative_path }
      let(:only_path) { false }

      it 'rewrites the link correctly' do
        doc = filter(link(upload_path))

        expect(doc.at_css('a')['href']).to eq(absolute_path)
        expect(doc.at_css('a').classes).to include('gfm')
        expect(doc.at_css('a')['data-link']).to eq('true')
      end
    end

    it 'rebuilds relative URL for a link' do
      doc = filter(link(upload_path))

      expect(doc.at_css('a')['href']).to eq(relative_path)
      expect(doc.at_css('a').classes).to include('gfm')
      expect(doc.at_css('a')['data-link']).to eq('true')

      doc = filter(nested(link(upload_path)))

      expect(doc.at_css('a')['href']).to eq(relative_path)
      expect(doc.at_css('a').classes).to include('gfm')
      expect(doc.at_css('a')['data-link']).to eq('true')
    end

    it 'rebuilds relative URL for an image' do
      doc = filter(image(upload_path))

      expect(doc.at_css('img')['src']).to eq(relative_path)
      expect(doc.at_css('img').classes).to include('gfm')
      expect(doc.at_css('img')['data-link']).not_to eq('true')

      doc = filter(nested(image(upload_path)))

      expect(doc.at_css('img')['src']).to eq(relative_path)
      expect(doc.at_css('img').classes).to include('gfm')
      expect(doc.at_css('img')['data-link']).not_to eq('true')
    end

    it 'does not modify absolute URL' do
      doc = filter(link('http://example.com'))

      expect(doc.at_css('a')['href']).to eq 'http://example.com'
      expect(doc.at_css('a').classes).not_to include('gfm')
      expect(doc.at_css('a')['data-link']).not_to eq('true')
    end

    it 'supports unescaped Unicode filenames' do
      path = '/uploads/한글.png'
      doc = filter(link(path))

      expect(doc.at_css('a')['href']).to eq("/#{project.full_path}/uploads/%ED%95%9C%EA%B8%80.png")
      expect(doc.at_css('a').classes).to include('gfm')
      expect(doc.at_css('a')['data-link']).to eq('true')
    end

    it 'supports escaped Unicode filenames' do
      path = '/uploads/한글.png'
      escaped = Addressable::URI.escape(path)
      doc = filter(image(escaped))

      expect(doc.at_css('img')['src']).to eq("/#{project.full_path}/uploads/%ED%95%9C%EA%B8%80.png")
      expect(doc.at_css('img').classes).to include('gfm')
      expect(doc.at_css('img')['data-link']).not_to eq('true')
    end
  end

  context 'to a group upload' do
    let(:upload_link) { link('/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg') }
    let_it_be(:group) { create(:group) }

    let(:project) { nil }
    let(:relative_path) { "/groups/#{group.full_path}/-/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg" }

    context 'with an absolute URL' do
      let(:absolute_path) { Gitlab.config.gitlab.url + relative_path }
      let(:only_path) { false }

      it 'rewrites the link correctly' do
        doc = filter(upload_link)

        expect(doc.at_css('a')['href']).to eq(absolute_path)
        expect(doc.at_css('a').classes).to include('gfm')
        expect(doc.at_css('a')['data-link']).to eq('true')
      end
    end

    it 'rewrites the link correctly' do
      doc = filter(upload_link)

      expect(doc.at_css('a')['href']).to eq(relative_path)
      expect(doc.at_css('a').classes).to include('gfm')
      expect(doc.at_css('a')['data-link']).to eq('true')
    end

    it 'rewrites the link correctly for subgroup' do
      group.update!(parent: create(:group))

      doc = filter(upload_link)

      expect(doc.at_css('a')['href']).to eq(relative_path)
      expect(doc.at_css('a').classes).to include('gfm')
      expect(doc.at_css('a')['data-link']).to eq('true')
    end

    it 'does not modify absolute URL' do
      doc = filter(link('http://example.com'))

      expect(doc.at_css('a')['href']).to eq 'http://example.com'
      expect(doc.at_css('a').classes).not_to include('gfm')
      expect(doc.at_css('a')['data-link']).not_to eq('true')
    end
  end

  context 'to a personal snippet' do
    let(:group) { nil }
    let(:project) { nil }
    let(:relative_path) { '/uploads/-/system/personal_snippet/6/674e4f07fbf0a7736c3439212896e51a/example.tar.gz' }

    context 'with an absolute URL' do
      let(:absolute_path) { Gitlab.config.gitlab.url + relative_path }
      let(:only_path) { false }

      it 'rewrites the link correctly' do
        doc = filter(link(relative_path))

        expect(doc.at_css('a')['href']).to eq(absolute_path)
        expect(doc.at_css('a').classes).to include('gfm')
        expect(doc.at_css('a')['data-link']).to eq('true')
      end
    end

    context 'with a relative URL root' do
      let(:gitlab_root) { '/gitlab' }
      let(:absolute_path) { Gitlab.config.gitlab.url + gitlab_root + relative_path }

      before do
        stub_config_setting(relative_url_root: gitlab_root)
      end

      context 'with an absolute URL' do
        let(:only_path) { false }

        it 'rewrites the link correctly' do
          doc = filter(link(relative_path))

          expect(doc.at_css('a')['href']).to eq(absolute_path)
          expect(doc.at_css('a').classes).to include('gfm')
          expect(doc.at_css('a')['data-link']).to eq('true')
        end
      end

      it 'rewrites the link correctly' do
        doc = filter(link(relative_path))

        expect(doc.at_css('a')['href']).to eq(gitlab_root + relative_path)
        expect(doc.at_css('a').classes).to include('gfm')
        expect(doc.at_css('a')['data-link']).to eq('true')
      end
    end

    it 'rewrites the link correctly' do
      doc = filter(link(relative_path))

      expect(doc.at_css('a')['href']).to eq(relative_path)
      expect(doc.at_css('a').classes).to include('gfm')
      expect(doc.at_css('a')['data-link']).to eq('true')
    end

    it 'does not modify absolute URL' do
      doc = filter(link('http://example.com'))

      expect(doc.at_css('a')['href']).to eq 'http://example.com'
      expect(doc.at_css('a').classes).not_to include('gfm')
      expect(doc.at_css('a')['data-link']).not_to eq('true')
    end
  end

  context 'invalid input' do
    using RSpec::Parameterized::TableSyntax

    where(:name, :href) do
      'invalid URI'                  | '://foo'
      'invalid UTF-8 byte sequences' | '%FF'
      'garbled path'                 | 'open(/var/tmp/):%20/location%0Afrom:%20/test'
      'whitespace'                   | "d18213acd3732630991986120e167e3d/Landscape_8.jpg\nand more"
      'null byte'                    | "%00"
    end

    with_them do
      it { expect { filter(link("/uploads/#{href}")) }.not_to raise_error }
    end
  end
end
