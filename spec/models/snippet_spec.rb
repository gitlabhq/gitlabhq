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
end
