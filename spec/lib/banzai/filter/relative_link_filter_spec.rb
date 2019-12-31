# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Filter::RelativeLinkFilter do
  include GitHelpers
  include RepoHelpers

  def filter(doc, contexts = {})
    contexts.reverse_merge!({
      commit:         commit,
      project:        project,
      current_user:   user,
      group:          group,
      project_wiki:   project_wiki,
      ref:            ref,
      requested_path: requested_path,
      only_path:      only_path
    })

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

  def allow_gitaly_n_plus_1
    Gitlab::GitalyClient.allow_n_plus_1_calls do
      yield
    end
  end

  let(:project)        { create(:project, :repository, :public) }
  let(:user)           { create(:user) }
  let(:group)          { nil }
  let(:project_path)   { project.full_path }
  let(:ref)            { 'markdown' }
  let(:commit)         { project.commit(ref) }
  let(:project_wiki)   { nil }
  let(:requested_path) { '/' }
  let(:only_path)      { true }

  it 'does not trigger a gitaly n+1', :request_store do
    raw_doc = ""

    allow_gitaly_n_plus_1 do
      30.times do |i|
        create_file_in_repo(project, ref, ref, "new_file_#{i}", "x" )
        raw_doc += link("new_file_#{i}")
      end
    end

    expect { filter(raw_doc) }.to change { Gitlab::GitalyClient.get_request_count }.by(2)
  end

  shared_examples :preserve_unchanged do
    it 'does not modify any relative URL in anchor' do
      doc = filter(link('README.md'))
      expect(doc.at_css('a')['href']).to eq 'README.md'
    end

    it 'does not modify any relative URL in image' do
      doc = filter(image('files/images/logo-black.png'))
      expect(doc.at_css('img')['src']).to eq 'files/images/logo-black.png'
    end

    it 'does not modify any relative URL in video' do
      doc = filter(video('files/videos/intro.mp4'), commit: project.commit('video'), ref: 'video')

      expect(doc.at_css('video')['src']).to eq 'files/videos/intro.mp4'
    end

    it 'does not modify any relative URL in audio' do
      doc = filter(audio('files/audio/sample.wav'), commit: project.commit('audio'), ref: 'audio')

      expect(doc.at_css('audio')['src']).to eq 'files/audio/sample.wav'
    end
  end

  context 'with a project_wiki' do
    let(:project_wiki) { double('ProjectWiki') }
    include_examples :preserve_unchanged
  end

  context 'without a repository' do
    let(:project) { create(:project) }
    include_examples :preserve_unchanged
  end

  context 'with an empty repository' do
    let(:project) { create(:project_empty_repo) }
    include_examples :preserve_unchanged
  end

  context 'without project repository access' do
    let(:project) { create(:project, :repository, repository_access_level: ProjectFeature::PRIVATE) }
    include_examples :preserve_unchanged
  end

  it 'does not raise an exception on invalid URIs' do
    act = link("://foo")
    expect { filter(act) }.not_to raise_error
  end

  it 'does not raise an exception on URIs containing invalid utf-8 byte sequences' do
    act = link("%FF")
    expect { filter(act) }.not_to raise_error
  end

  it 'does not raise an exception on URIs containing invalid utf-8 byte sequences in uploads' do
    act = link("/uploads/%FF")
    expect { filter(act) }.not_to raise_error
  end

  it 'does not raise an exception on URIs containing invalid utf-8 byte sequences in context requested path' do
    expect { filter(link("files/test.md"), requested_path: '%FF') }.not_to raise_error
  end

  it 'does not raise an exception with a garbled path' do
    act = link("open(/var/tmp/):%20/location%0Afrom:%20/test")
    expect { filter(act) }.not_to raise_error
  end

  it 'does not explode with an escaped null byte' do
    act = link("/%00")
    expect { filter(act) }.not_to raise_error
  end

  it 'does not raise an exception with a space in the path' do
    act = link("/uploads/d18213acd3732630991986120e167e3d/Landscape_8.jpg  \nBut here's some more unexpected text :smile:)")
    expect { filter(act) }.not_to raise_error
  end

  it 'ignores ref if commit is passed' do
    doc = filter(link('non/existent.file'), commit: project.commit('empty-branch') )
    expect(doc.at_css('a')['href'])
      .to eq "/#{project_path}/#{ref}/non/existent.file" # non-existent files have no leading blob/raw/tree
  end

  shared_examples :valid_repository do
    it 'rebuilds absolute URL for a file in the repo' do
      doc = filter(link('/doc/api/README.md'))
      expect(doc.at_css('a')['href'])
        .to eq "/#{project_path}/blob/#{ref}/doc/api/README.md"
    end

    it 'does not modify relative URLs in system notes' do
      path = "#{project_path}/merge_requests/1/diffs"
      doc = filter(link(path), system_note: true)

      expect(doc.at_css('a')['href']).to eq path
    end

    it 'ignores absolute URLs with two leading slashes' do
      doc = filter(link('//doc/api/README.md'))
      expect(doc.at_css('a')['href']).to eq '//doc/api/README.md'
    end

    it 'rebuilds relative URL for a file in the repo' do
      doc = filter(link('doc/api/README.md'))
      expect(doc.at_css('a')['href'])
        .to eq "/#{project_path}/blob/#{ref}/doc/api/README.md"
    end

    it 'rebuilds relative URL for a file in the repo with leading ./' do
      doc = filter(link('./doc/api/README.md'))
      expect(doc.at_css('a')['href'])
        .to eq "/#{project_path}/blob/#{ref}/doc/api/README.md"
    end

    it 'rebuilds relative URL for a file in the repo up one directory' do
      relative_link = link('../api/README.md')
      doc = filter(relative_link, requested_path: 'doc/update/7.14-to-8.0.md')

      expect(doc.at_css('a')['href'])
        .to eq "/#{project_path}/blob/#{ref}/doc/api/README.md"
    end

    it 'rebuilds relative URL for a file in the repo up multiple directories' do
      relative_link = link('../../../api/README.md')
      doc = filter(relative_link, requested_path: 'doc/foo/bar/baz/README.md')

      expect(doc.at_css('a')['href'])
        .to eq "/#{project_path}/blob/#{ref}/doc/api/README.md"
    end

    it 'rebuilds relative URL for a file in the repository root' do
      relative_link = link('../README.md')
      doc = filter(relative_link, requested_path: 'doc/some-file.md')

      expect(doc.at_css('a')['href'])
        .to eq "/#{project_path}/blob/#{ref}/README.md"
    end

    it 'rebuilds relative URL for a file in the repo with an anchor' do
      doc = filter(link('README.md#section'))
      expect(doc.at_css('a')['href'])
        .to eq "/#{project_path}/blob/#{ref}/README.md#section"
    end

    it 'rebuilds relative URL for a directory in the repo' do
      doc = filter(link('doc/api/'))
      expect(doc.at_css('a')['href'])
        .to eq "/#{project_path}/tree/#{ref}/doc/api"
    end

    it 'rebuilds relative URL for an image in the repo' do
      doc = filter(image('files/images/logo-black.png'))

      expect(doc.at_css('img')['src'])
        .to eq "/#{project_path}/raw/#{ref}/files/images/logo-black.png"
    end

    it 'rebuilds relative URL for link to an image in the repo' do
      doc = filter(link('files/images/logo-black.png'))

      expect(doc.at_css('a')['href'])
        .to eq "/#{project_path}/raw/#{ref}/files/images/logo-black.png"
    end

    it 'rebuilds relative URL for a video in the repo' do
      doc = filter(video('files/videos/intro.mp4'), commit: project.commit('video'), ref: 'video')

      expect(doc.at_css('video')['src'])
        .to eq "/#{project_path}/raw/video/files/videos/intro.mp4"
    end

    it 'rebuilds relative URL for audio in the repo' do
      doc = filter(audio('files/audio/sample.wav'), commit: project.commit('audio'), ref: 'audio')

      expect(doc.at_css('audio')['src'])
        .to eq "/#{project_path}/raw/audio/files/audio/sample.wav"
    end

    it 'does not modify relative URL with an anchor only' do
      doc = filter(link('#section-1'))
      expect(doc.at_css('a')['href']).to eq '#section-1'
    end

    it 'does not modify absolute URL' do
      doc = filter(link('http://example.com'))
      expect(doc.at_css('a')['href']).to eq 'http://example.com'
    end

    it 'does not call gitaly' do
      filter(link('http://example.com'))

      expect(described_class).not_to receive(:get_blob_types)
    end

    it 'supports Unicode filenames' do
      path = 'files/images/한글.png'
      escaped = Addressable::URI.escape(path)

      # Stub this method so the file doesn't actually need to be in the repo
      allow_any_instance_of(described_class).to receive(:uri_type).and_return(:raw)

      doc = filter(image(escaped))
      expect(doc.at_css('img')['src']).to eq "/#{project_path}/raw/#{Addressable::URI.escape(ref)}/#{escaped}"
    end

    context 'when requested path is a file in the repo' do
      let(:requested_path) { 'doc/api/README.md' }
      it 'rebuilds URL relative to the containing directory' do
        doc = filter(link('users.md'))
        expect(doc.at_css('a')['href']).to eq "/#{project_path}/blob/#{Addressable::URI.escape(ref)}/doc/api/users.md"
      end
    end

    context 'when requested path is a directory in the repo' do
      let(:requested_path) { 'doc/api/' }
      it 'rebuilds URL relative to the directory' do
        doc = filter(link('users.md'))
        expect(doc.at_css('a')['href']).to eq "/#{project_path}/blob/#{Addressable::URI.escape(ref)}/doc/api/users.md"
      end
    end

    context 'when ref name contains percent sign' do
      let(:ref) { '100%branch' }
      let(:commit) { project.commit('1b12f15a11fc6e62177bef08f47bc7b5ce50b141') }
      let(:requested_path) { 'foo/bar/' }
      it 'correctly escapes the ref' do
        doc = filter(link('.gitkeep'))
        expect(doc.at_css('a')['href']).to eq "/#{project_path}/blob/#{Addressable::URI.escape(ref)}/foo/bar/.gitkeep"
      end
    end

    context 'when ref name contains special chars' do
      let(:ref) { 'mark#\'@],+;-._/#@!$&()+down' }
      let(:path) { 'files/images/logo-black.png' }

      it 'correctly escapes the ref' do
        # Addressable won't escape the '#', so we do this manually
        ref_escaped = 'mark%23\'@%5D,+;-._/%23@!$&()+down'

        # Stub this method so the branch doesn't actually need to be in the repo
        allow_any_instance_of(described_class).to receive(:uri_type).and_return(:raw)
        allow_any_instance_of(described_class).to receive(:get_uri_types).and_return({ path: :tree })

        doc = filter(link(path))

        expect(doc.at_css('a')['href'])
          .to eq "/#{project_path}/raw/#{ref_escaped}/files/images/logo-black.png"
      end
    end

    context 'when requested path is a directory with space in the repo' do
      let(:ref) { 'master' }
      let(:commit) { project.commit('38008cb17ce1466d8fec2dfa6f6ab8dcfe5cf49e') }
      let(:requested_path) { 'with space/' }
      it 'does not escape the space twice' do
        doc = filter(link('README.md'))
        expect(doc.at_css('a')['href']).to eq "/#{project_path}/blob/#{Addressable::URI.escape(ref)}/with%20space/README.md"
      end
    end
  end

  context 'with a valid commit' do
    include_examples :valid_repository
  end

  context 'with a valid ref' do
    let(:commit) { nil } # force filter to use ref instead of commit
    include_examples :valid_repository
  end

  context 'with a /upload/ URL' do
    # not needed
    let(:commit) { nil }
    let(:ref) { nil }
    let(:requested_path) { nil }
    let(:upload_path) { '/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg' }
    let(:relative_path) { "/#{project.full_path}#{upload_path}" }

    context 'to a project upload' do
      shared_examples 'rewrite project uploads' do
        context 'with an absolute URL' do
          let(:absolute_path) { Gitlab.config.gitlab.url + relative_path }
          let(:only_path) { false }

          it 'rewrites the link correctly' do
            doc = filter(link(upload_path))

            expect(doc.at_css('a')['href']).to eq(absolute_path)
          end
        end

        it 'rebuilds relative URL for a link' do
          doc = filter(link(upload_path))
          expect(doc.at_css('a')['href']).to eq(relative_path)

          doc = filter(nested(link(upload_path)))
          expect(doc.at_css('a')['href']).to eq(relative_path)
        end

        it 'rebuilds relative URL for an image' do
          doc = filter(image(upload_path))
          expect(doc.at_css('img')['src']).to eq(relative_path)

          doc = filter(nested(image(upload_path)))
          expect(doc.at_css('img')['src']).to eq(relative_path)
        end

        it 'does not modify absolute URL' do
          doc = filter(link('http://example.com'))
          expect(doc.at_css('a')['href']).to eq 'http://example.com'
        end

        it 'supports unescaped Unicode filenames' do
          path = '/uploads/한글.png'
          doc = filter(link(path))

          expect(doc.at_css('a')['href']).to eq("/#{project.full_path}/uploads/%ED%95%9C%EA%B8%80.png")
        end

        it 'supports escaped Unicode filenames' do
          path = '/uploads/한글.png'
          escaped = Addressable::URI.escape(path)
          doc = filter(image(escaped))

          expect(doc.at_css('img')['src']).to eq("/#{project.full_path}/uploads/%ED%95%9C%EA%B8%80.png")
        end
      end

      context 'without project repository access' do
        let(:project) { create(:project, :repository, repository_access_level: ProjectFeature::PRIVATE) }

        it_behaves_like 'rewrite project uploads'
      end

      context 'with project repository access' do
        it_behaves_like 'rewrite project uploads'
      end
    end

    context 'to a group upload' do
      let(:upload_link) { link('/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg') }
      let(:group) { create(:group) }
      let(:project) { nil }
      let(:relative_path) { "/groups/#{group.full_path}/-/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg" }

      context 'with an absolute URL' do
        let(:absolute_path) { Gitlab.config.gitlab.url + relative_path }
        let(:only_path) { false }

        it 'rewrites the link correctly' do
          doc = filter(upload_link)

          expect(doc.at_css('a')['href']).to eq(absolute_path)
        end
      end

      it 'rewrites the link correctly' do
        doc = filter(upload_link)

        expect(doc.at_css('a')['href']).to eq(relative_path)
      end

      it 'rewrites the link correctly for subgroup' do
        group.update!(parent: create(:group))

        doc = filter(upload_link)

        expect(doc.at_css('a')['href']).to eq(relative_path)
      end

      it 'does not modify absolute URL' do
        doc = filter(link('http://example.com'))

        expect(doc.at_css('a')['href']).to eq 'http://example.com'
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
          end
        end

        it 'rewrites the link correctly' do
          doc = filter(link(relative_path))

          expect(doc.at_css('a')['href']).to eq(gitlab_root + relative_path)
        end
      end

      it 'rewrites the link correctly' do
        doc = filter(link(relative_path))

        expect(doc.at_css('a')['href']).to eq(relative_path)
      end

      it 'does not modify absolute URL' do
        doc = filter(link('http://example.com'))

        expect(doc.at_css('a')['href']).to eq 'http://example.com'
      end
    end
  end
end
