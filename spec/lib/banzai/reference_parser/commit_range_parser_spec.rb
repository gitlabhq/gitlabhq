require 'spec_helper'

describe Banzai::ReferenceParser::CommitRangeParser do
  include ReferenceParserHelpers

  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }
  subject { described_class.new(Banzai::RenderContext.new(project, user)) }
  let(:link) { empty_html_link }

  describe '#nodes_visible_to_user' do
    context 'when the link has a data-issue attribute' do
      before do
        link['data-commit-range'] = '123..456'
      end

      it_behaves_like "referenced feature visibility", "repository"
    end
  end

  describe '#referenced_by' do
    context 'when the link has a data-project attribute' do
      before do
        link['data-project'] = project.id.to_s
      end

      context 'when the link as a data-commit-range attribute' do
        before do
          link['data-commit-range'] = '123..456'
        end

        it 'returns an Array of commit ranges' do
          range = double(:range)

          expect(subject).to receive(:find_object)
            .with(project, '123..456')
            .and_return(range)

          expect(subject.referenced_by([link])).to eq([range])
        end

        it 'returns an empty Array when the commit range could not be found' do
          expect(subject).to receive(:find_object)
            .with(project, '123..456')
            .and_return(nil)

          expect(subject.referenced_by([link])).to eq([])
        end
      end

      context 'when the link does not have a data-commit-range attribute' do
        it 'returns an empty Array' do
          expect(subject.referenced_by([link])).to eq([])
        end
      end
    end

    context 'when the link does not have a data-project attribute' do
      it 'returns an empty Array' do
        expect(subject.referenced_by([link])).to eq([])
      end
    end
  end

  describe '#commit_range_ids_per_project' do
    before do
      link['data-project'] = project.id.to_s
    end

    it 'returns a Hash containing range IDs per project' do
      link['data-commit-range'] = '123..456'

      hash = subject.commit_range_ids_per_project([link])

      expect(hash).to be_an_instance_of(Hash)

      expect(hash[project.id].to_a).to eq(['123..456'])
    end

    it 'does not add a project when the data-commit-range attribute is empty' do
      hash = subject.commit_range_ids_per_project([link])

      expect(hash).to be_empty
    end
  end

  describe '#find_ranges' do
    it 'returns an Array of range objects' do
      range = double(:commit)

      expect(subject).to receive(:find_object)
        .with(project, '123..456')
        .and_return(range)

      expect(subject.find_ranges(project, ['123..456'])).to eq([range])
    end

    it 'skips ranges that could not be found' do
      expect(subject).to receive(:find_object)
        .with(project, '123..456')
        .and_return(nil)

      expect(subject.find_ranges(project, ['123..456'])).to eq([])
    end
  end

  describe '#find_object' do
    let(:range) { double(:range) }

    context 'when the range has valid commits' do
      it 'returns the commit range' do
        expect(CommitRange).to receive(:new).and_return(range)
        expect(range).to receive(:valid_commits?).and_return(true)

        expect(subject.find_object(project, '123..456')).to eq(range)
      end
    end

    context 'when the range does not have any valid commits' do
      it 'returns nil' do
        expect(CommitRange).to receive(:new).and_return(range)
        expect(range).to receive(:valid_commits?).and_return(false)

        expect(subject.find_object(project, '123..456')).to be_nil
      end
    end

    context 'group context' do
      it 'returns nil' do
        group = create(:group)

        expect(subject.find_object(group, '123..456')).to be_nil
      end
    end
  end
end
