# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Snippet do
  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Gitlab::VisibilityLevel) }
    it { is_expected.to include_module(Participable) }
    it { is_expected.to include_module(Referable) }
    it { is_expected.to include_module(Sortable) }
    it { is_expected.to include_module(Awardable) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:notes).dependent(:destroy) }
    it { is_expected.to have_many(:award_emoji).dependent(:destroy) }
    it { is_expected.to have_many(:user_mentions).class_name("SnippetUserMention") }
    it { is_expected.to have_one(:snippet_repository) }
    it { is_expected.to have_one(:statistics).class_name('SnippetStatistics').dependent(:destroy) }
    it { is_expected.to have_many(:repository_storage_moves).class_name('Snippets::RepositoryStorageMove').inverse_of(:container) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:author) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(255) }

    it { is_expected.to validate_length_of(:file_name).is_at_most(255) }

    it { is_expected.to validate_presence_of(:content) }

    it { is_expected.to validate_inclusion_of(:visibility_level).in_array(Gitlab::VisibilityLevel.values) }

    it do
      allow(Gitlab::CurrentSettings).to receive(:snippet_size_limit).and_return(1)

      is_expected
        .to validate_length_of(:content)
              .is_at_most(Gitlab::CurrentSettings.snippet_size_limit)
              .with_message("is too long (2 Bytes). The maximum size is 1 Byte.")
    end

    context 'content validations' do
      context 'with existing snippets' do
        let(:snippet) { create(:personal_snippet, content: 'This is a valid content at the time of creation') }

        before do
          expect(snippet).to be_valid

          stub_application_setting(snippet_size_limit: 2)
        end

        it 'does not raise a validation error if the content is not changed' do
          snippet.title = 'new title'

          expect(snippet).to be_valid
        end

        it 'raises and error if the content is changed and the size is bigger than limit' do
          snippet.content = snippet.content + "test"

          expect(snippet).not_to be_valid
        end
      end

      context 'with new snippets' do
        let(:limit) { 15 }

        before do
          stub_application_setting(snippet_size_limit: limit)
        end

        it 'is valid when content is smaller than the limit' do
          snippet = build(:personal_snippet, content: 'Valid Content')

          expect(snippet).to be_valid
        end

        it 'raises error when content is bigger than setting limit' do
          snippet = build(:personal_snippet, content: 'This is an invalid content')

          aggregate_failures do
            expect(snippet).not_to be_valid
            expect(snippet.errors[:content]).to include("is too long (#{snippet.content.size} Bytes). The maximum size is #{limit} Bytes.")
          end
        end
      end
    end
  end

  describe 'callbacks' do
    it 'creates snippet statistics when the snippet is created' do
      snippet = build(:snippet)
      expect(snippet.statistics).to be_nil

      snippet.save

      expect(snippet.statistics).to be_persisted
    end
  end

  describe '#to_reference' do
    context 'when snippet belongs to a project' do
      let(:project) { build(:project, name: 'sample-project') }
      let(:snippet) { build(:snippet, id: 1, project: project) }

      it 'returns a String reference to the object' do
        expect(snippet.to_reference).to eq "$1"
      end

      it 'supports a cross-project reference' do
        another_project = build(:project, name: 'another-project', namespace: project.namespace)
        expect(snippet.to_reference(another_project)).to eq "sample-project$1"
      end
    end

    context 'when snippet does not belong to a project' do
      let(:snippet) { build(:snippet, id: 1, project: nil) }

      it 'returns a String reference to the object' do
        expect(snippet.to_reference).to eq "$1"
      end

      it 'still returns shortest reference when project arg present' do
        another_project = build(:project, name: 'another-project')
        expect(snippet.to_reference(another_project)).to eq "$1"
      end
    end
  end

  describe '#file_name' do
    let(:snippet) { build(:snippet, file_name: file_name) }

    context 'file_name is nil' do
      let(:file_name) { nil }

      it 'returns an empty string' do
        expect(snippet.file_name).to eq ''
      end
    end

    context 'file_name is not nil' do
      let(:file_name) { 'foo.txt' }

      it 'returns the file_name' do
        expect(snippet.file_name).to eq file_name
      end
    end
  end

  describe "#content_html_invalidated?" do
    let(:snippet) { create(:snippet, content: "md", content_html: "html", file_name: "foo.md") }

    it "invalidates the HTML cache of content when the filename changes" do
      expect { snippet.file_name = "foo.rb" }.to change { snippet.content_html_invalidated? }.from(false).to(true)
    end
  end

  describe '.search' do
    let_it_be(:snippet) { create(:snippet, title: 'test snippet', description: 'description') }

    it 'returns snippets with a matching title' do
      expect(described_class.search(snippet.title)).to eq([snippet])
    end

    it 'returns snippets with a partially matching title' do
      expect(described_class.search(snippet.title[0..2])).to eq([snippet])
    end

    it 'returns snippets with a matching title regardless of the casing' do
      expect(described_class.search(snippet.title.upcase)).to eq([snippet])
    end

    it 'returns snippets with a matching file name' do
      expect(described_class.search(snippet.file_name)).to eq([snippet])
    end

    it 'returns snippets with a partially matching file name' do
      expect(described_class.search(snippet.file_name[0..2])).to eq([snippet])
    end

    it 'returns snippets with a matching file name regardless of the casing' do
      expect(described_class.search(snippet.file_name.upcase)).to eq([snippet])
    end

    it 'returns snippets with a matching description' do
      expect(described_class.search(snippet.description)).to eq([snippet])
    end
  end

  describe 'when default snippet visibility set to internal' do
    using RSpec::Parameterized::TableSyntax

    before do
      stub_application_setting(default_snippet_visibility: Gitlab::VisibilityLevel::INTERNAL)
    end

    where(:attribute_name, :value) do
      :visibility | 'private'
      :visibility_level | Gitlab::VisibilityLevel::PRIVATE
      'visibility' | 'private'
      'visibility_level' | Gitlab::VisibilityLevel::PRIVATE
    end

    with_them do
      it 'sets the visibility level' do
        snippet = described_class.new(attribute_name => value, title: 'test', file_name: 'test.rb', content: 'test data')

        expect(snippet.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
        expect(snippet.title).to eq('test')
        expect(snippet.file_name).to eq('test.rb')
        expect(snippet.content).to eq('test data')
      end
    end
  end

  describe '.with_optional_visibility' do
    let_it_be(:public_snippet) { create(:snippet, :public) }
    let_it_be(:private_snippet) { create(:snippet, :private) }

    context 'when a visibility level is provided' do
      it 'returns snippets with the given visibility' do
        snippets = described_class
          .with_optional_visibility(Gitlab::VisibilityLevel::PUBLIC)

        expect(snippets).to eq([public_snippet])
      end
    end

    context 'when a visibility level is not provided' do
      it 'returns all snippets' do
        snippets = described_class.with_optional_visibility

        expect(snippets).to include(public_snippet, private_snippet)
      end
    end
  end

  describe '.only_personal_snippets' do
    it 'returns snippets not associated with any projects' do
      create(:project_snippet)

      snippet = create(:snippet)
      snippets = described_class.only_personal_snippets

      expect(snippets).to eq([snippet])
    end
  end

  describe '.only_include_projects_visible_to' do
    let_it_be(:author)   { create(:user) }
    let_it_be(:project1) { create(:project_empty_repo, :public, namespace: author.namespace) }
    let_it_be(:project2) { create(:project_empty_repo, :internal, namespace: author.namespace) }
    let_it_be(:project3) { create(:project_empty_repo, :private, namespace: author.namespace) }
    let_it_be(:snippet1) { create(:project_snippet, project: project1, author: author) }
    let_it_be(:snippet2) { create(:project_snippet, project: project2, author: author) }
    let_it_be(:snippet3) { create(:project_snippet, project: project3, author: author) }

    context 'when a user is provided' do
      it 'returns snippets visible to the user' do
        user = create(:user)

        snippets = described_class.only_include_projects_visible_to(user)

        expect(snippets).to include(snippet1, snippet2)
        expect(snippets).not_to include(snippet3)
      end
    end

    context 'when a user is not provided' do
      it 'returns snippets visible to anonymous users' do
        snippets = described_class.only_include_projects_visible_to

        expect(snippets).to include(snippet1)
        expect(snippets).not_to include(snippet2, snippet3)
      end
    end
  end

  describe 'only_include_projects_with_snippets_enabled' do
    let_it_be(:project, reload: true) { create(:project_empty_repo) }
    let_it_be(:snippet) { create(:project_snippet, project: project) }

    let(:access_level) { ProjectFeature::ENABLED }

    before do
      project.project_feature.update(snippets_access_level: access_level)
    end

    it 'includes snippets for projects with snippets enabled' do
      snippets = described_class.only_include_projects_with_snippets_enabled

      expect(snippets).to eq([snippet])
    end

    context 'when snippet_access_level is private' do
      let(:access_level) { ProjectFeature::PRIVATE }

      context 'when the include_private option is enabled' do
        it 'includes snippets for projects with snippets set to private' do
          snippets = described_class.only_include_projects_with_snippets_enabled(include_private: true)

          expect(snippets).to eq([snippet])
        end
      end

      context 'when the include_private option is not enabled' do
        it 'does not include snippets for projects that have snippets set to private' do
          snippets = described_class.only_include_projects_with_snippets_enabled

          expect(snippets).to be_empty
        end
      end
    end
  end

  describe '.only_include_authorized_projects' do
    it 'only includes snippets for projects the user is authorized to see' do
      user = create(:user)
      project1 = create(:project_empty_repo, :private)
      project2 = create(:project_empty_repo, :private)

      project1.team.add_developer(user)

      create(:project_snippet, project: project2)

      snippet = create(:project_snippet, project: project1)
      snippets = described_class.only_include_authorized_projects(user)

      expect(snippets).to eq([snippet])
    end
  end

  describe '.for_project_with_user' do
    let_it_be(:public_project) { create(:project_empty_repo, :public) }
    let_it_be(:private_project) { create(:project_empty_repo, :private) }

    context 'when a user is provided' do
      let_it_be(:user) { create(:user) }

      it 'returns an empty collection if the user can not view the snippets' do
        create(:project_snippet, :public, project: private_project)

        expect(described_class.for_project_with_user(private_project, user)).to be_empty
      end

      it 'returns the snippets if the user is a member of the project' do
        snippet = create(:project_snippet, project: private_project)

        private_project.team.add_developer(user)

        snippets = described_class.for_project_with_user(private_project, user)

        expect(snippets).to eq([snippet])
      end

      it 'returns public snippets for a public project the user is not a member of' do
        snippet = create(:project_snippet, :public, project: public_project)

        create(:project_snippet, :private, project: public_project)

        snippets = described_class.for_project_with_user(public_project, user)

        expect(snippets).to eq([snippet])
      end
    end

    context 'when a user is not provided' do
      it 'returns an empty collection for a private project' do
        create(:project_snippet, :public, project: private_project)

        expect(described_class.for_project_with_user(private_project)).to be_empty
      end

      it 'returns public snippets for a public project' do
        snippet = create(:project_snippet, :public, project: public_project)

        create(:project_snippet, :private, project: public_project)

        snippets = described_class.for_project_with_user(public_project)

        expect(snippets).to eq([snippet])
      end
    end
  end

  describe '.visible_to_or_authored_by' do
    it 'returns snippets visible to the user' do
      user = create(:user)
      snippet1 = create(:snippet, :public)
      snippet2 = create(:snippet, :private, author: user)
      snippet3 = create(:snippet, :private)

      snippets = described_class.visible_to_or_authored_by(user)

      expect(snippets).to include(snippet1, snippet2)
      expect(snippets).not_to include(snippet3)
    end
  end

  describe '#participants' do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:snippet) { create(:snippet, content: 'foo', project: project) }

    let_it_be(:note1) do
      create(:note_on_project_snippet,
             noteable: snippet,
             project: project,
             note: 'a')
    end

    let_it_be(:note2) do
      create(:note_on_project_snippet,
             noteable: snippet,
             project: project,
             note: 'b')
    end

    it 'includes the snippet author and note authors' do
      expect(snippet.participants).to include(snippet.author, note1.author, note2.author)
    end
  end

  describe '#check_for_spam' do
    let(:snippet) { create(:snippet, visibility_level: visibility_level) }

    subject do
      snippet.assign_attributes(title: title)
      snippet.check_for_spam?
    end

    context 'when public and spammable attributes changed' do
      let(:visibility_level) { Snippet::PUBLIC }
      let(:title) { 'woo' }

      it 'returns true' do
        is_expected.to be_truthy
      end
    end

    context 'when private' do
      let(:visibility_level) { Snippet::PRIVATE }
      let(:title) { snippet.title }

      it 'returns false' do
        is_expected.to be_falsey
      end

      it 'returns true when switching to public' do
        snippet.save!
        snippet.visibility_level = Snippet::PUBLIC

        expect(snippet.check_for_spam?).to be_truthy
      end
    end

    context 'when spammable attributes have not changed' do
      let(:visibility_level) { Snippet::PUBLIC }
      let(:title) { snippet.title }

      it 'returns false' do
        is_expected.to be_falsey
      end
    end
  end

  describe '#blob' do
    let(:snippet) { build(:snippet) }

    it 'returns a blob representing the snippet data' do
      blob = snippet.blob

      expect(blob).to be_a(Blob)
      expect(blob.path).to eq(snippet.file_name)
      expect(blob.data).to eq(snippet.content)
    end
  end

  describe '#blobs' do
    context 'when repository does not exist' do
      let(:snippet) { create(:snippet) }

      it 'returns empty array' do
        expect(snippet.blobs).to be_empty
      end
    end

    context 'when repository exists' do
      let(:snippet) { create(:snippet, :repository) }

      it 'returns array of blobs' do
        expect(snippet.blobs).to all(be_a(Blob))
      end

      context 'when file does not exist' do
        it 'removes nil values from the blobs array' do
          allow(snippet).to receive(:list_files).and_return(%w(LICENSE non_existent_snippet_file))

          blobs = snippet.blobs
          expect(blobs.count).to eq 1
          expect(blobs.first.name).to eq 'LICENSE'
        end
      end
    end
  end

  describe '#to_json' do
    let(:snippet) { build(:snippet) }

    it 'excludes secret_token from generated json' do
      expect(Gitlab::Json.parse(to_json).keys).not_to include("secret_token")
    end

    it 'does not override existing exclude option value' do
      expect(Gitlab::Json.parse(to_json(except: [:id])).keys).not_to include("secret_token", "id")
    end

    def to_json(params = {})
      snippet.to_json(params)
    end
  end

  describe '#storage' do
    let(:snippet) { build(:snippet, id: 1) }

    it "stores snippet in #{Storage::Hashed::SNIPPET_REPOSITORY_PATH_PREFIX} dir" do
      expect(snippet.storage.disk_path).to start_with Storage::Hashed::SNIPPET_REPOSITORY_PATH_PREFIX
    end
  end

  describe '#track_snippet_repository' do
    let(:snippet) { create(:snippet) }
    let(:shard_name) { 'foo' }

    subject { snippet.track_snippet_repository(shard_name) }

    context 'when a snippet repository entry does not exist' do
      it 'creates a new entry' do
        expect { subject }.to change(snippet, :snippet_repository)
      end

      it 'tracks the snippet storage location' do
        subject

        expect(snippet.snippet_repository).to have_attributes(
          disk_path: snippet.disk_path,
          shard_name: shard_name
        )
      end
    end

    context 'when a tracking entry exists' do
      let!(:snippet) { create(:snippet, :repository) }
      let(:snippet_repository) { snippet.snippet_repository }
      let(:shard_name) { 'bar' }

      it 'does not create a new entry in the database' do
        expect { subject }.not_to change(snippet, :snippet_repository)
      end

      it 'updates the snippet storage location' do
        allow(snippet).to receive(:disk_path).and_return('fancy/new/path')

        subject

        expect(snippet.snippet_repository).to have_attributes(
          disk_path: 'fancy/new/path',
          shard_name: shard_name
        )
      end
    end
  end

  describe '#create_repository' do
    let(:snippet) { create(:snippet) }

    subject { snippet.create_repository }

    it 'creates the repository' do
      expect(snippet.repository).to receive(:after_create).and_call_original

      expect(subject).to be_truthy
      expect(snippet.repository.exists?).to be_truthy
    end

    it 'tracks snippet repository' do
      expect do
        subject
      end.to change(SnippetRepository, :count).by(1)
    end

    it 'sets same shard in snippet repository as in the repository storage' do
      expect(snippet).to receive(:repository_storage).and_return('picked')
      expect(snippet).to receive(:repository_exists?).and_return(false)
      expect(snippet.repository).to receive(:create_if_not_exists)

      subject

      expect(snippet.snippet_repository.shard_name).to eq 'picked'
    end

    context 'when repository exists' do
      let!(:snippet) { create(:snippet, :repository) }

      it 'does not try to create repository' do
        expect(snippet.repository).not_to receive(:after_create)

        expect(snippet.create_repository).to be_nil
      end

      context 'when snippet_repository exists' do
        it 'does not create a new snippet repository' do
          expect do
            snippet.create_repository
          end.not_to change(SnippetRepository, :count)
        end
      end

      context 'when snippet_repository does not exist' do
        it 'creates a snippet_repository' do
          snippet.snippet_repository.destroy
          snippet.reload

          expect do
            snippet.create_repository
          end.to change(SnippetRepository, :count).by(1)
        end
      end
    end
  end

  describe '#repository_storage' do
    let(:snippet) { create(:snippet) }

    subject { snippet.repository_storage }

    before do
      expect(Repository).to receive(:pick_storage_shard).and_return('picked')
    end

    it 'returns repository storage from ApplicationSetting' do
      expect(subject).to eq 'picked'
    end

    context 'when snippet_project is already created' do
      let!(:snippet_repository) { create(:snippet_repository, snippet: snippet) }

      before do
        allow(snippet_repository).to receive(:shard_name).and_return('foo')
      end

      it 'returns repository_storage from snippet_project' do
        expect(subject).to eq 'foo'
      end
    end
  end

  describe '#repository_size_checker' do
    subject { build(:personal_snippet) }

    let(:checker) { subject.repository_size_checker }
    let(:current_size) { 60 }
    let(:namespace) { nil }

    before do
      allow(subject.repository).to receive(:size).and_return(current_size)
    end

    include_examples 'size checker for snippet'
  end

  describe '#can_cache_field?' do
    using RSpec::Parameterized::TableSyntax

    let(:snippet) { create(:snippet, file_name: file_name) }

    subject { snippet.can_cache_field?(field) }

    where(:field, :file_name, :result) do
      :title       | nil           | true
      :title       | 'foo.bar'     | true
      :description | nil           | true
      :description | 'foo.bar'     | true
      :content     | nil           | false
      :content     | 'bar.foo'     | false
      :content     | 'markdown.md' | true
    end

    with_them do
      it { is_expected.to eq result }
    end
  end

  describe '#url_to_repo' do
    subject { snippet.url_to_repo }

    context 'with personal snippet' do
      let(:snippet) { create(:personal_snippet) }

      it { is_expected.to eq(Gitlab.config.gitlab_shell.ssh_path_prefix + "snippets/#{snippet.id}.git") }
    end

    context 'with project snippet' do
      let(:snippet) { create(:project_snippet) }

      it { is_expected.to eq(Gitlab.config.gitlab_shell.ssh_path_prefix + "#{snippet.project.full_path}/snippets/#{snippet.id}.git") }
    end
  end

  describe '.max_file_limit' do
    subject { described_class.max_file_limit }

    it "returns #{Snippet::MAX_FILE_COUNT}" do
      expect(subject).to eq Snippet::MAX_FILE_COUNT
    end
  end

  describe '#list_files' do
    let_it_be(:snippet) { create(:snippet, :repository) }

    let(:ref) { 'test-ref' }

    subject { snippet.list_files(ref) }

    context 'when snippet has a repository' do
      it 'lists files from the repository with the ref' do
        expect(snippet.repository).to receive(:ls_files).with(ref)

        subject
      end

      context 'when ref is nil' do
        let(:ref) { nil }

        it 'lists files from the repository from the deafult_branch' do
          expect(snippet.repository).to receive(:ls_files).with(snippet.default_branch)

          subject
        end
      end
    end

    context 'when snippet does not have a repository' do
      before do
        allow(snippet.repository).to receive(:empty?).and_return(true)
      end

      it 'returns an empty array' do
        expect(subject).to be_empty
      end
    end
  end

  describe '#multiple_files?' do
    subject { snippet.multiple_files? }

    context 'when snippet has multiple files' do
      let(:snippet) { create(:snippet, :repository) }

      it { is_expected.to be_truthy }
    end

    context 'when snippet does not have multiple files' do
      let(:snippet) { create(:snippet, :empty_repo) }

      it { is_expected.to be_falsey }
    end

    context 'when the snippet does not have a repository' do
      let(:snippet) { build(:snippet) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#git_transfer_in_progress?' do
    let(:snippet) { build(:snippet) }

    subject { snippet.git_transfer_in_progress? }

    it 'returns true when there are git transfers' do
      allow(snippet).to receive(:reference_counter).with(type: Gitlab::GlRepository::SNIPPET) do
        double(:reference_counter, value: 2)
      end

      expect(subject).to eq true
    end

    it 'returns false when there are not git transfers' do
      allow(snippet).to receive(:reference_counter).with(type: Gitlab::GlRepository::SNIPPET) do
        double(:reference_counter, value: 0)
      end

      expect(subject).to eq false
    end
  end

  it_behaves_like 'can move repository storage' do
    let_it_be(:container) { create(:snippet, :repository) }
  end

  describe '#change_head_to_default_branch' do
    let(:head_path) { Rails.root.join(TestEnv.repos_path, "#{snippet.disk_path}.git", 'HEAD') }

    subject { snippet.change_head_to_default_branch }

    context 'when repository does not exist' do
      let(:snippet) { create(:snippet) }

      it 'does nothing' do
        expect(snippet.repository_exists?).to eq false
        expect(snippet.repository.raw_repository).not_to receive(:write_ref)

        subject
      end
    end

    context 'when repository is empty' do
      let(:snippet) { create(:snippet, :empty_repo) }

      before do
        allow(Gitlab::CurrentSettings).to receive(:default_branch_name).and_return(default_branch)
      end

      context 'when default branch in settings is different from "master"' do
        let(:default_branch) { 'custom-branch' }

        it 'changes the HEAD reference to the default branch' do
          expect { subject }.to change { File.read(head_path).squish }.to("ref: refs/heads/#{default_branch}")
        end
      end
    end

    context 'when repository is not empty' do
      let(:snippet) { create(:snippet, :empty_repo) }

      before do
        populate_snippet_repo
      end

      context 'when HEAD branch is empty' do
        it 'changes HEAD to default branch' do
          File.write(head_path, 'ref: refs/heads/non_existen_branch')
          expect(File.read(head_path).squish).to eq 'ref: refs/heads/non_existen_branch'

          subject

          expect(File.read(head_path).squish).to eq 'ref: refs/heads/main'
          expect(snippet.list_files('HEAD')).not_to be_empty
        end
      end

      context 'when HEAD branch is not empty' do
        it 'does nothing' do
          File.write(head_path, 'ref: refs/heads/main')

          expect(snippet.repository.raw_repository).not_to receive(:write_ref)

          subject
        end
      end

      def populate_snippet_repo
        allow(Gitlab::CurrentSettings).to receive(:default_branch_name).and_return('main')

        data = [{ file_path: 'new_file_test', content: 'bar' }]
        snippet.snippet_repository.multi_files_action(snippet.author, data, branch_name: 'main', message: 'foo')
      end
    end
  end
end
