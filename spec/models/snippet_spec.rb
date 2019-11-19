# frozen_string_literal: true

require 'spec_helper'

describe Snippet do
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
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:author) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(255) }

    it { is_expected.to validate_length_of(:file_name).is_at_most(255) }

    it { is_expected.to validate_presence_of(:content) }

    it { is_expected.to validate_inclusion_of(:visibility_level).in_array(Gitlab::VisibilityLevel.values) }
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
    let(:project) { create(:project) }

    context 'file_name is nil' do
      let(:snippet) { create(:snippet, project: project, file_name: nil) }

      it 'returns an empty string' do
        expect(snippet.file_name).to eq ''
      end
    end

    context 'file_name is not nil' do
      let(:snippet) { create(:snippet, project: project, file_name: 'foo.txt') }

      it 'returns the file_name' do
        expect(snippet.file_name).to eq 'foo.txt'
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
    let(:snippet) { create(:snippet, title: 'test snippet') }

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
  end

  describe '.search_code' do
    let(:snippet) { create(:snippet, content: 'class Foo; end') }

    it 'returns snippets with matching content' do
      expect(described_class.search_code(snippet.content)).to eq([snippet])
    end

    it 'returns snippets with partially matching content' do
      expect(described_class.search_code('class')).to eq([snippet])
    end

    it 'returns snippets with matching content regardless of the casing' do
      expect(described_class.search_code('FOO')).to eq([snippet])
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
    context 'when a visibility level is provided' do
      it 'returns snippets with the given visibility' do
        create(:snippet, :private)

        snippet = create(:snippet, :public)
        snippets = described_class
          .with_optional_visibility(Gitlab::VisibilityLevel::PUBLIC)

        expect(snippets).to eq([snippet])
      end
    end

    context 'when a visibility level is not provided' do
      it 'returns all snippets' do
        snippet1 = create(:snippet, :public)
        snippet2 = create(:snippet, :private)
        snippets = described_class.with_optional_visibility

        expect(snippets).to include(snippet1, snippet2)
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
    let!(:project1) { create(:project, :public) }
    let!(:project2) { create(:project, :internal) }
    let!(:project3) { create(:project, :private) }
    let!(:snippet1) { create(:project_snippet, project: project1) }
    let!(:snippet2) { create(:project_snippet, project: project2) }
    let!(:snippet3) { create(:project_snippet, project: project3) }

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
    context 'when the include_private option is enabled' do
      it 'includes snippets for projects with snippets set to private' do
        project = create(:project)

        project.project_feature
          .update(snippets_access_level: ProjectFeature::PRIVATE)

        snippet = create(:project_snippet, project: project)

        snippets = described_class
          .only_include_projects_with_snippets_enabled(include_private: true)

        expect(snippets).to eq([snippet])
      end
    end

    context 'when the include_private option is not enabled' do
      it 'does not include snippets for projects that have snippets set to private' do
        project = create(:project)

        project.project_feature
          .update(snippets_access_level: ProjectFeature::PRIVATE)

        create(:project_snippet, project: project)

        snippets = described_class.only_include_projects_with_snippets_enabled

        expect(snippets).to be_empty
      end
    end

    it 'includes snippets for projects with snippets enabled' do
      project = create(:project)

      project.project_feature
        .update(snippets_access_level: ProjectFeature::ENABLED)

      snippet = create(:project_snippet, project: project)
      snippets = described_class.only_include_projects_with_snippets_enabled

      expect(snippets).to eq([snippet])
    end
  end

  describe '.only_include_authorized_projects' do
    it 'only includes snippets for projects the user is authorized to see' do
      user = create(:user)
      project1 = create(:project, :private)
      project2 = create(:project, :private)

      project1.team.add_developer(user)

      create(:project_snippet, project: project2)

      snippet = create(:project_snippet, project: project1)
      snippets = described_class.only_include_authorized_projects(user)

      expect(snippets).to eq([snippet])
    end
  end

  describe '.for_project_with_user' do
    context 'when a user is provided' do
      it 'returns an empty collection if the user can not view the snippets' do
        project = create(:project, :private)
        user = create(:user)

        project.project_feature
          .update(snippets_access_level: ProjectFeature::ENABLED)

        create(:project_snippet, :public, project: project)

        expect(described_class.for_project_with_user(project, user)).to be_empty
      end

      it 'returns the snippets if the user is a member of the project' do
        project = create(:project, :private)
        user = create(:user)
        snippet = create(:project_snippet, project: project)

        project.team.add_developer(user)

        snippets = described_class.for_project_with_user(project, user)

        expect(snippets).to eq([snippet])
      end

      it 'returns public snippets for a public project the user is not a member of' do
        project = create(:project, :public)

        project.project_feature
          .update(snippets_access_level: ProjectFeature::ENABLED)

        user = create(:user)
        snippet = create(:project_snippet, :public, project: project)

        create(:project_snippet, :private, project: project)

        snippets = described_class.for_project_with_user(project, user)

        expect(snippets).to eq([snippet])
      end
    end

    context 'when a user is not provided' do
      it 'returns an empty collection for a private project' do
        project = create(:project, :private)

        project.project_feature
          .update(snippets_access_level: ProjectFeature::ENABLED)

        create(:project_snippet, :public, project: project)

        expect(described_class.for_project_with_user(project)).to be_empty
      end

      it 'returns public snippets for a public project' do
        project = create(:project, :public)
        snippet = create(:project_snippet, :public, project: project)

        project.project_feature
          .update(snippets_access_level: ProjectFeature::PUBLIC)

        create(:project_snippet, :private, project: project)

        snippets = described_class.for_project_with_user(project)

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
    let(:project) { create(:project, :public) }
    let(:snippet) { create(:snippet, content: 'foo', project: project) }

    let!(:note1) do
      create(:note_on_project_snippet,
             noteable: snippet,
             project: project,
             note: 'a')
    end

    let!(:note2) do
      create(:note_on_project_snippet,
             noteable: snippet,
             project: project,
             note: 'b')
    end

    it 'includes the snippet author' do
      expect(snippet.participants).to include(snippet.author)
    end

    it 'includes the note authors' do
      expect(snippet.participants).to include(note1.author, note2.author)
    end
  end

  describe '#check_for_spam' do
    let(:snippet) { create :snippet, visibility_level: visibility_level }

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
    let(:snippet) { create(:snippet) }

    it 'returns a blob representing the snippet data' do
      blob = snippet.blob

      expect(blob).to be_a(Blob)
      expect(blob.path).to eq(snippet.file_name)
      expect(blob.data).to eq(snippet.content)
    end
  end

  describe '#to_json' do
    let(:snippet) { build(:snippet) }

    it 'excludes secret_token from generated json' do
      expect(JSON.parse(to_json).keys).not_to include("secret_token")
    end

    it 'does not override existing exclude option value' do
      expect(JSON.parse(to_json(except: [:id])).keys).not_to include("secret_token", "id")
    end

    def to_json(params = {})
      snippet.to_json(params)
    end
  end
end
