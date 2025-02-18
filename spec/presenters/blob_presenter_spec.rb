# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlobPresenter do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.first_owner }

  let(:repository) { project.repository }
  let(:blob) { repository.blob_at(ref, path) }
  let(:ref) { 'HEAD' }
  let(:path) { 'files/ruby/regex.rb' }

  subject(:presenter) { described_class.new(blob, current_user: user) }

  describe '#web_url' do
    it { expect(presenter.web_url).to eq("http://localhost/#{project.full_path}/-/blob/#{ref}/#{path}") }
  end

  describe '#web_path' do
    it { expect(presenter.web_path).to eq("/#{project.full_path}/-/blob/#{ref}/#{path}") }
  end

  describe '#edit_blob_path' do
    it { expect(presenter.edit_blob_path).to eq("/#{project.full_path}/-/edit/#{ref}/#{path}") }
  end

  describe '#raw_path' do
    it { expect(presenter.raw_path).to eq("/#{project.full_path}/-/raw/#{ref}/#{path}") }
  end

  describe '#replace_path' do
    it { expect(presenter.replace_path).to eq("/#{project.full_path}/-/update/#{ref}/#{path}") }
  end

  shared_examples_for '#can_current_user_push_to_branch?' do
    let(:branch_exists) { true }

    before do
      allow(project.repository).to receive(:branch_exists?).with(blob.commit_id).and_return(branch_exists)
    end

    it { expect(presenter.can_current_user_push_to_branch?).to eq(true) }

    context 'current_user is nil' do
      let(:user) { nil }

      it { expect(presenter.can_current_user_push_to_branch?).to eq(false) }
    end

    context 'branch does not exist' do
      let(:branch_exists) { false }

      it { expect(presenter.can_current_user_push_to_branch?).to eq(false) }
    end
  end

  context 'when blob has ref_type' do
    %w[heads tags].each do |ref_type|
      context "when ref_type is #{ref_type}" do
        before do
          blob.ref_type = ref_type
        end

        describe '#web_url' do
          it { expect(presenter.web_url).to eq("http://localhost/#{project.full_path}/-/blob/#{ref}/#{path}?ref_type=#{ref_type}") }
        end

        describe '#web_path' do
          it { expect(presenter.web_path).to eq("/#{project.full_path}/-/blob/#{ref}/#{path}?ref_type=#{ref_type}") }
        end

        describe '#edit_blob_path' do
          it { expect(presenter.edit_blob_path).to eq("/#{project.full_path}/-/edit/#{ref}/#{path}?ref_type=#{ref_type}") }
        end

        describe '#raw_path' do
          it { expect(presenter.raw_path).to eq("/#{project.full_path}/-/raw/#{ref}/#{path}?ref_type=#{ref_type}") }
        end

        describe '#replace_path' do
          it { expect(presenter.replace_path).to eq("/#{project.full_path}/-/update/#{ref}/#{path}?ref_type=#{ref_type}") }
        end

        describe '#history_path' do
          it { expect(presenter.history_path).to eq("/#{project.full_path}/-/commits/#{ref}/#{path}?ref_type=#{ref_type}") }
        end

        describe '#blame_path' do
          it { expect(presenter.blame_path).to eq("/#{project.full_path}/-/blame/#{ref}/#{path}?ref_type=#{ref_type}") }
        end

        it_behaves_like '#can_current_user_push_to_branch?'
      end
    end
  end

  describe '#can_modify_blob?' do
    context 'when blob is store externally' do
      before do
        allow(blob).to receive(:stored_externally?).and_return(true)
      end

      it { expect(presenter.can_modify_blob?).to be_falsey }
    end

    context 'when the user cannot edit the tree' do
      before do
        allow(presenter).to receive(:can_edit_tree?).with(project, ref).and_return(false)
      end

      it { expect(presenter.can_modify_blob?).to be_falsey }
    end

    context 'when ref is a branch' do
      let(:ref) { 'feature' }

      it { expect(presenter.can_modify_blob?).to be_truthy }
    end
  end

  describe '#can_modify_blob_with_web_ide?' do
    before do
      allow(blob).to receive(:stored_externally?).and_return(false)
      allow(presenter).to receive(:can_collaborate_with_project?).with(project).and_return(false)
    end

    it { expect(presenter.can_modify_blob_with_web_ide?).to be_falsey }

    context 'when blob is stored externally' do
      before do
        allow(blob).to receive(:stored_externally?).and_return(true)
      end

      it { expect(presenter.can_modify_blob_with_web_ide?).to be_falsey }
    end

    context 'when user can collaborate with the project' do
      before do
        allow(presenter).to receive(:can_collaborate_with_project?).with(project).and_return(true)
      end

      it { expect(presenter.can_modify_blob_with_web_ide?).to be_truthy }
    end
  end

  describe '#can_current_user_push_to_branch?' do
    context 'when ref is a branch' do
      let(:ref) { 'feature' }

      it 'delegates to UserAccess' do
        allow_next_instance_of(Gitlab::UserAccess) do |instance|
          expect(instance).to receive(:can_push_to_branch?).with(ref).and_call_original
        end
        expect(presenter.can_current_user_push_to_branch?).to be_truthy
      end
    end

    it_behaves_like '#can_current_user_push_to_branch?'

    it { expect(presenter.can_current_user_push_to_branch?).to be_falsey }
  end

  describe '#archived?' do
    it { expect(presenter.archived?).to eq(project.archived) }
  end

  describe '#pipeline_editor_path' do
    context 'when blob is .gitlab-ci.yml' do
      before_all do
        project.repository.create_file(
          user,
          '.gitlab-ci.yml',
          '',
          message: 'Add a ci file',
          branch_name: 'main'
        )
      end

      let(:ref) { 'main' }
      let(:path) { '.gitlab-ci.yml' }

      it { expect(presenter.pipeline_editor_path).to eq("/#{project.full_path}/-/ci/editor?branch_name=#{ref}") }

      context 'when ref includes the qualifier' do
        let(:ref) { 'refs/heads/main' }

        it 'returns path to unqualified ref' do
          allow(blob).to receive(:ref_type).and_return('heads')

          expect(presenter.pipeline_editor_path).to eq("/#{project.full_path}/-/ci/editor?branch_name=main")
        end
      end
    end
  end

  context 'Gitpod' do
    let(:gitpod_url) { "https://gitpod.io" }
    let(:gitpod_application_enabled) { true }
    let(:gitpod_user_enabled) { true }

    before do
      allow(user).to receive(:gitpod_enabled).and_return(gitpod_user_enabled)
      allow(Gitlab::CurrentSettings).to receive(:gitpod_enabled).and_return(gitpod_application_enabled)
      allow(Gitlab::CurrentSettings).to receive(:gitpod_url).and_return(gitpod_url)
    end

    context 'Gitpod enabled for application and user' do
      describe '#gitpod_blob_url' do
        it { expect(presenter.gitpod_blob_url).to eq("#{gitpod_url}##{"http://localhost/#{project.full_path}/-/tree/#{ref}/#{path}"}") }
      end
    end

    context 'Gitpod disabled at application level' do
      let(:gitpod_application_enabled) { false }

      describe '#gitpod_blob_url' do
        it { expect(presenter.gitpod_blob_url).to eq(nil) }
      end
    end

    context 'Gitpod disabled at user level' do
      let(:gitpod_user_enabled) { false }

      describe '#gitpod_blob_url' do
        it { expect(presenter.gitpod_blob_url).to eq(nil) }
      end
    end
  end

  describe '#find_file_path' do
    it { expect(presenter.find_file_path).to eq("/#{project.full_path}/-/find_file/HEAD") }
  end

  describe '#blame_path' do
    it { expect(presenter.blame_path).to eq("/#{project.full_path}/-/blame/HEAD/files/ruby/regex.rb") }
  end

  describe '#history_path' do
    it { expect(presenter.history_path).to eq("/#{project.full_path}/-/commits/HEAD/files/ruby/regex.rb") }
  end

  describe '#permalink_path' do
    it { expect(presenter.permalink_path).to eq("/#{project.full_path}/-/blob/#{project.repository.commit(blob.commit_id).sha}/files/ruby/regex.rb") }
  end

  context 'environment has been deployed' do
    let(:external_url) { "https://some.environment" }
    let(:environment) { create(:environment, project: project, external_url: external_url) }
    let!(:deployment) { create(:deployment, :success, environment: environment, project: project, sha: blob.commit_id) }

    before do
      allow(project).to receive(:public_path_for_source_path).with(path, blob.commit_id).and_return(path)
    end

    describe '#environment_formatted_external_url' do
      it { expect(presenter.environment_formatted_external_url).to eq("some.environment") }
    end

    describe '#environment_external_url_for_route_map' do
      it { expect(presenter.environment_external_url_for_route_map).to eq("#{external_url}/#{path}") }
    end

    describe 'chooses the latest deployed environment for #environment_formatted_external_url and #environment_external_url_for_route_map' do
      let(:another_external_url) { "https://another.environment" }
      let(:another_environment) { create(:environment, project: project, external_url: another_external_url) }
      let!(:another_deployment) { create(:deployment, :success, environment: another_environment, project: project, sha: blob.commit_id) }

      it { expect(presenter.environment_formatted_external_url).to eq("another.environment") }
      it { expect(presenter.environment_external_url_for_route_map).to eq("#{another_external_url}/#{path}") }
    end
  end

  describe '#code_owners' do
    it { expect(presenter.code_owners).to be_empty }
  end

  describe '#ide_edit_path' do
    it { expect(presenter.ide_edit_path).to eq("/-/ide/project/#{project.full_path}/edit/HEAD/-/files/ruby/regex.rb") }
  end

  describe '#fork_and_edit_path' do
    it 'generates expected URI + query' do
      uri = URI.parse(presenter.fork_and_edit_path)
      query = Rack::Utils.parse_query(uri.query)

      expect(uri.path).to eq("/#{project.full_path}/-/forks")
      expect(query).to include('continue[to]' => presenter.edit_blob_path, 'namespace_key' => user.namespace_id.to_s)
    end

    context 'current_user is nil' do
      let(:user) { nil }

      it { expect(presenter.fork_and_edit_path).to be_nil }
    end
  end

  describe '#ide_fork_and_edit_path' do
    it 'generates expected URI + query' do
      uri = URI.parse(presenter.ide_fork_and_edit_path)
      query = Rack::Utils.parse_query(uri.query)

      expect(uri.path).to eq("/#{project.full_path}/-/forks")
      expect(query).to include('continue[to]' => presenter.ide_edit_path, 'namespace_key' => user.namespace_id.to_s)
    end

    context 'current_user is nil' do
      let(:user) { nil }

      it { expect(presenter.ide_fork_and_edit_path).to be_nil }
    end
  end

  describe '#code_navigation_path' do
    let(:code_navigation_path) { Gitlab::CodeNavigationPath.new(project, blob.commit_id).full_json_path_for(path) }

    it { expect(presenter.code_navigation_path).to eq(code_navigation_path) }
  end

  describe '#project_blob_path_root' do
    it { expect(presenter.project_blob_path_root).to eq("/#{project.full_path}/-/blob/HEAD") }
  end

  context 'given a Gitlab::Graphql::Representation::TreeEntry' do
    let(:blob) { Gitlab::Graphql::Representation::TreeEntry.new(super(), repository) }

    describe '#web_url' do
      it { expect(presenter.web_url).to eq("http://localhost/#{project.full_path}/-/blob/#{ref}/#{path}") }
    end

    describe '#web_path' do
      it { expect(presenter.web_path).to eq("/#{project.full_path}/-/blob/#{ref}/#{path}") }
    end
  end

  describe '#highlight' do
    let(:git_blob) { blob.__getobj__ }

    it 'returns highlighted content' do
      expect(Gitlab::Highlight).to receive(:highlight).with('files/ruby/regex.rb', git_blob.data, plain: nil, language: 'ruby', used_on: :blob)

      presenter.highlight
    end

    it 'returns plain content when :plain is true' do
      expect(Gitlab::Highlight).to receive(:highlight).with('files/ruby/regex.rb', git_blob.data, plain: true, language: 'ruby', used_on: :blob)

      presenter.highlight(plain: true)
    end

    context '"to" param is present' do
      before do
        allow(git_blob)
          .to receive(:data)
          .and_return("line one\nline two\nline 3")
      end

      it 'returns limited highlighted content' do
        expect(Gitlab::Highlight).to receive(:highlight).with('files/ruby/regex.rb', "line one\n", plain: nil, language: 'ruby', used_on: :blob)

        presenter.highlight(to: 1)
      end
    end

    context 'gitlab-language contains a match' do
      before do
        allow(blob).to receive(:language_from_gitattributes).and_return('ruby')
      end

      it 'passes language to inner call' do
        expect(Gitlab::Highlight).to receive(:highlight).with('files/ruby/regex.rb', git_blob.data, plain: nil, language: 'ruby', used_on: :blob)

        presenter.highlight
      end
    end

    context 'when used_on param is present' do
      it 'returns highlighted content' do
        expect(Gitlab::Highlight).to receive(:highlight).with('files/ruby/regex.rb', git_blob.data, plain: nil, language: 'ruby', used_on: :diff)

        presenter.highlight(used_on: :diff)
      end
    end
  end

  describe '#highlight_and_trim' do
    let(:git_blob) { blob.__getobj__ }

    it 'returns trimmed content for longer line' do
      trimmed_lines = git_blob.data.split("\n").map { |line| line[0, 55] }.join("\n")

      expect(Gitlab::Highlight).to receive(:highlight).with('files/ruby/regex.rb', "#{trimmed_lines}\n", plain: nil, language: 'ruby', context: { ellipsis_svg: "svg_icon", ellipsis_indexes: [21, 26, 49] })

      presenter.highlight_and_trim(ellipsis_svg: "svg_icon", trim_length: 55)
    end
  end

  describe '#blob_language' do
    subject { presenter.blob_language }

    it { is_expected.to eq('ruby') }

    context 'gitlab-language contains a match' do
      before do
        allow(blob).to receive(:language_from_gitattributes).and_return('cpp')
      end

      it { is_expected.to eq('cpp') }
    end

    context 'when blob is binary' do
      let(:blob) { repository.blob_at('HEAD', 'Gemfile.zip') }

      it { is_expected.to be_nil }
    end
  end

  describe '#base64_encoded_blob' do
    let(:blob) { repository.blob_at('HEAD', file) }
    let(:file) { 'files/ruby/popen.rb' }

    it 'does not include html in the content' do
      expect(presenter.base64_encoded_blob.include?('</span>')).to be_falsey
    end

    it 'encodes the raw blob base 64' do
      expect(presenter.base64_encoded_blob).to include("cmVxdWlyZSAnZmlsZXV0")
      expect(presenter.base64_encoded_blob).to include("R1cwogIGVuZAplbmQK\n")
    end
  end

  describe '#raw_plain_data' do
    let(:blob) { repository.blob_at('HEAD', file) }

    context 'when blob is text' do
      let(:file) { 'files/ruby/popen.rb' }

      it 'does not include html in the content' do
        expect(presenter.raw_plain_data.include?('</span>')).to be_falsey
      end
    end
  end

  describe '#plain_data' do
    let(:blob) { repository.blob_at('HEAD', file) }

    context 'when blob is binary' do
      let(:file) { 'files/images/logo-black.png' }

      it 'returns nil' do
        expect(presenter.plain_data).to be_nil
      end
    end

    context 'when blob is markup' do
      let(:file) { 'README.md' }

      it 'returns plain content' do
        expect(presenter.plain_data).to include('<span id="LC1" class="line" lang="markdown">')
      end
    end

    context 'when blob has syntax' do
      let(:file) { 'files/ruby/regex.rb' }

      it 'returns highlighted syntax content' do
        expect(presenter.plain_data)
          .to include '<span id="LC1" class="line" lang="ruby"><span class="k">module</span> <span class="nn">Gitlab</span>'
      end
    end

    context 'when blob has plain data' do
      let(:file) { 'LICENSE' }

      it 'returns plain text highlighted content' do
        expect(presenter.plain_data).to include('<span id="LC1" class="line" lang="plaintext">The MIT License (MIT)</span>')
      end
    end
  end
end
