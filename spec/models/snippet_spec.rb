require 'spec_helper'

describe Snippet, models: true do
  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Gitlab::VisibilityLevel) }
    it { is_expected.to include_module(Linguist::BlobHelper) }
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
    it { is_expected.to validate_length_of(:title).is_within(0..255) }

    it { is_expected.to validate_length_of(:file_name).is_within(0..255) }

    it { is_expected.to validate_presence_of(:content) }

    it { is_expected.to validate_inclusion_of(:visibility_level).in_array(Gitlab::VisibilityLevel.values) }
  end

  describe '#to_reference' do
    let(:project) { create(:empty_project) }
    let(:snippet) { create(:snippet, project: project) }

    it 'returns a String reference to the object' do
      expect(snippet.to_reference).to eq "$#{snippet.id}"
    end

    it 'supports a cross-project reference' do
      cross = double('project')
      expect(snippet.to_reference(cross)).to eq "#{project.to_reference}$#{snippet.id}"
    end
  end

  describe '.search' do
    let(:snippet) { create(:snippet) }

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

  describe '.accessible_to' do
    let(:author)  { create(:author) }
    let(:project) { create(:empty_project) }

    let!(:public_snippet)   { create(:snippet, :public) }
    let!(:internal_snippet) { create(:snippet, :internal) }
    let!(:private_snippet)  { create(:snippet, :private, author: author) }

    let!(:project_public_snippet)   { create(:snippet, :public, project: project) }
    let!(:project_internal_snippet) { create(:snippet, :internal, project: project) }
    let!(:project_private_snippet)  { create(:snippet, :private, project: project) }

    it 'returns only public snippets when user is blank' do
      expect(described_class.accessible_to(nil)).to match_array [public_snippet, project_public_snippet]
    end

    it 'returns only public, and internal snippets for regular users' do
      user = create(:user)

      expect(described_class.accessible_to(user)).to match_array [public_snippet, internal_snippet, project_public_snippet, project_internal_snippet]
    end

    it 'returns public, internal snippets and project private snippets for project members' do
      member = create(:user)
      project.team << [member, :developer]

      expect(described_class.accessible_to(member)).to match_array [public_snippet, internal_snippet, project_public_snippet, project_internal_snippet, project_private_snippet]
    end

    it 'returns private snippets where the user is the author' do
      expect(described_class.accessible_to(author)).to match_array [public_snippet, internal_snippet, private_snippet, project_public_snippet, project_internal_snippet]
    end

    it 'returns all snippets when for admins' do
      admin = create(:admin)

      expect(described_class.accessible_to(admin)).to match_array [public_snippet, internal_snippet, private_snippet, project_public_snippet, project_internal_snippet, project_private_snippet]
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
end
