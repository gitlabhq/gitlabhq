# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::RepositoryLinkFilter, feature_category: :markdown do
  include RepoHelpers

  def filter(doc, contexts = {})
    contexts.reverse_merge!({
      commit: commit,
      project: project,
      current_user: user,
      group: group,
      wiki: wiki,
      ref: ref,
      requested_path: requested_path,
      only_path: only_path
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
  let(:wiki)           { nil }
  let(:requested_path) { '/' }
  let(:only_path)      { true }

  it 'does not trigger a gitaly n+1', :request_store do
    raw_doc = ""

    allow_gitaly_n_plus_1 do
      30.times do |i|
        create_file_in_repo(project, ref, ref, "new_file_#{i}", "x")
        raw_doc += link("new_file_#{i}")
      end
    end

    expect { filter(raw_doc) }.to change { Gitlab::GitalyClient.get_request_count }.by(2)
  end

  shared_examples 'preserve unchanged' do
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

  context 'with a wiki' do
    let(:wiki) { double('ProjectWiki') }

    include_examples 'preserve unchanged'
  end

  context 'without a repository' do
    let(:project) { create(:project) }

    include_examples 'preserve unchanged'
  end

  context 'with an empty repository' do
    let(:project) { create(:project_empty_repo) }

    include_examples 'preserve unchanged'
  end

  context 'without project repository access' do
    let(:project) { create(:project, :repository, repository_access_level: ProjectFeature::PRIVATE) }

    include_examples 'preserve unchanged'
  end

  it 'does not raise an exception on invalid URIs' do
    act = link("://foo")
    expect { filter(act) }.not_to raise_error
  end

  it 'does not raise an exception on URIs containing invalid utf-8 byte sequences' do
    act = link("%FF")
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

  it 'ignores ref if commit is passed' do
    doc = filter(link('non/existent.file'), commit: project.commit('empty-branch'))
    expect(doc.at_css('a')['href'])
      .to eq "/#{project_path}/-/blob/#{ref}/non/existent.file"
  end

  shared_examples 'valid repository' do
    it 'handles Gitaly unavailable exceptions gracefully' do
      allow_next_instance_of(Gitlab::GitalyClient::BlobService) do |blob_service|
        allow(blob_service).to receive(:get_blob_types).and_raise(GRPC::Unavailable)
      end

      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
        an_instance_of(GRPC::Unavailable), project_id: project.id
      )
      doc = ""
      expect { doc = filter(link('doc/api/README.md')) }.not_to raise_error
      expect(doc.at_css('a')['href'])
          .to eq "/#{project_path}/-/blob/#{ref}/doc/api/README.md"
    end

    it 'handles Gitaly timeout exceptions gracefully' do
      allow_next_instance_of(Gitlab::GitalyClient::BlobService) do |blob_service|
        allow(blob_service).to receive(:get_blob_types).and_raise(GRPC::DeadlineExceeded)
      end

      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
        an_instance_of(GRPC::DeadlineExceeded), project_id: project.id
      )
      doc = ""
      expect { doc = filter(link('doc/api/README.md')) }.not_to raise_error
      expect(doc.at_css('a')['href'])
          .to eq "/#{project_path}/-/blob/#{ref}/doc/api/README.md"
    end

    it 'rebuilds absolute URL for a file in the repo' do
      doc = filter(link('/doc/api/README.md'))
      expect(doc.at_css('a')['href'])
        .to eq "/#{project_path}/-/blob/#{ref}/doc/api/README.md"
    end

    it 'does not modify relative URLs in system notes' do
      path = "#{project_path}/-/merge_requests/1/diffs"
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
        .to eq "/#{project_path}/-/blob/#{ref}/doc/api/README.md"
    end

    it 'rebuilds relative URL for a missing file in the repo' do
      doc = filter(link('missing-file'))
      expect(doc.at_css('a')['href'])
        .to eq "/#{project_path}/-/blob/#{ref}/missing-file"
    end

    it 'rebuilds relative URL for a file in the repo with leading ./' do
      doc = filter(link('./doc/api/README.md'))
      expect(doc.at_css('a')['href'])
        .to eq "/#{project_path}/-/blob/#{ref}/doc/api/README.md"
    end

    it 'rebuilds relative URL for a file in the repo up one directory' do
      relative_link = link('../api/README.md')
      doc = filter(relative_link, requested_path: 'doc/update/7.14-to-8.0.md')

      expect(doc.at_css('a')['href'])
        .to eq "/#{project_path}/-/blob/#{ref}/doc/api/README.md"
    end

    it 'rebuilds relative URL for a file in the repo up multiple directories' do
      relative_link = link('../../../api/README.md')
      doc = filter(relative_link, requested_path: 'doc/foo/bar/baz/README.md')

      expect(doc.at_css('a')['href'])
        .to eq "/#{project_path}/-/blob/#{ref}/doc/api/README.md"
    end

    it 'rebuilds relative URL for a file in the repository root' do
      relative_link = link('../README.md')
      doc = filter(relative_link, requested_path: 'doc/some-file.md')

      expect(doc.at_css('a')['href'])
        .to eq "/#{project_path}/-/blob/#{ref}/README.md"
    end

    it 'rebuilds relative URL for a file in the repo with an anchor' do
      doc = filter(link('README.md#section'))
      expect(doc.at_css('a')['href'])
        .to eq "/#{project_path}/-/blob/#{ref}/README.md#section"
    end

    it 'rebuilds relative URL for a directory in the repo' do
      doc = filter(link('doc/api/'))
      expect(doc.at_css('a')['href'])
        .to eq "/#{project_path}/-/tree/#{ref}/doc/api"
    end

    it 'rebuilds relative URL for an image in the repo' do
      doc = filter(image('files/images/logo-black.png'))

      expect(doc.at_css('img')['src'])
        .to eq "/#{project_path}/-/raw/#{ref}/files/images/logo-black.png"
    end

    it 'rebuilds relative URL for link to an image in the repo' do
      doc = filter(link('files/images/logo-black.png'))

      expect(doc.at_css('a')['href'])
        .to eq "/#{project_path}/-/raw/#{ref}/files/images/logo-black.png"
    end

    it 'rebuilds relative URL for a video in the repo' do
      doc = filter(video('files/videos/intro.mp4'), commit: project.commit('video'), ref: 'video')

      expect(doc.at_css('video')['src'])
        .to eq "/#{project_path}/-/raw/video/files/videos/intro.mp4"
    end

    it 'rebuilds relative URL for audio in the repo' do
      doc = filter(audio('files/audio/sample.wav'), commit: project.commit('audio'), ref: 'audio')

      expect(doc.at_css('audio')['src'])
        .to eq "/#{project_path}/-/raw/audio/files/audio/sample.wav"
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
      expect(doc.at_css('img')['src']).to eq "/#{project_path}/-/raw/#{Addressable::URI.escape(ref)}/#{escaped}"
    end

    it 'supports percent sign in filenames' do
      doc = filter(link('doc/api/README%.md'))
      expect(doc.at_css('a')['href'])
        .to eq "/#{project_path}/-/blob/#{ref}/doc/api/README%25.md"
    end

    context 'when requested path is a file in the repo' do
      let(:requested_path) { 'doc/api/README.md' }

      it 'rebuilds URL relative to the containing directory' do
        doc = filter(link('users.md'))
        expect(doc.at_css('a')['href']).to eq "/#{project_path}/-/blob/#{Addressable::URI.escape(ref)}/doc/api/users.md"
      end
    end

    context 'when requested path is a directory in the repo' do
      let(:requested_path) { 'doc/api/' }

      it 'rebuilds URL relative to the directory' do
        doc = filter(link('users.md'))
        expect(doc.at_css('a')['href']).to eq "/#{project_path}/-/blob/#{Addressable::URI.escape(ref)}/doc/api/users.md"
      end
    end

    context 'when ref name contains percent sign' do
      let(:ref) { '100%branch' }
      let(:commit) { project.commit('1b12f15a11fc6e62177bef08f47bc7b5ce50b141') }
      let(:requested_path) { 'foo/bar/' }

      it 'correctly escapes the ref' do
        doc = filter(link('.gitkeep'))
        expect(doc.at_css('a')['href']).to eq "/#{project_path}/-/blob/#{Addressable::URI.escape(ref)}/foo/bar/.gitkeep"
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
          .to eq "/#{project_path}/-/raw/#{ref_escaped}/files/images/logo-black.png"
      end
    end

    context 'when requested path is a directory with space in the repo' do
      let(:ref) { 'master' }
      let(:commit) { project.commit('38008cb17ce1466d8fec2dfa6f6ab8dcfe5cf49e') }
      let(:requested_path) { 'with space/' }

      it 'does not escape the space twice' do
        doc = filter(link('README.md'))
        expect(doc.at_css('a')['href']).to eq "/#{project_path}/-/blob/#{Addressable::URI.escape(ref)}/with%20space/README.md"
      end
    end
  end

  context 'when public project repo with a valid commit' do
    include_examples 'valid repository'
  end

  context 'when private project repo with a valid commit' do
    let_it_be(:project) { create(:project, :repository, :private) }

    before do
      # user must have `read_code` ability
      project.add_developer(user)
    end

    include_examples 'valid repository'
  end

  context 'with a valid ref' do
    # force filter to use ref instead of commit
    let(:commit) { nil }

    include_examples 'valid repository'
  end

  it_behaves_like 'pipeline timing check'
end
