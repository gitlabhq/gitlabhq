require 'spec_helper'

describe Banzai::ReferenceParser::CommitParser, lib: true do
  let(:project) { create(:empty_project, :public) }
  let(:user) { create(:user) }
  let(:parser) { described_class.new(project, user, user) }
  let(:link) { Nokogiri::HTML.fragment('<a></a>').children[0] }

  describe '#referenced_by' do
    context 'when the link has a data-project attribute' do
      before do
        link['data-project'] = project.id.to_s
      end

      context 'when the link has a data-commit attribute' do
        before do
          link['data-commit'] = '123'
        end

        it 'returns an Array of commits' do
          commit = double(:commit)

          expect(parser).to receive(:find_object).
            with(project, '123').
            and_return(commit)

          expect(parser.referenced_by(link)).to eq([commit])
        end

        it 'returns an empty Array when the commit could not be found' do
          expect(parser).to receive(:find_object).
            with(project, '123').
            and_return(nil)

          expect(parser.referenced_by(link)).to eq([])
        end
      end

      context 'when the link does not have a data-commit attribute' do
        it 'returns an empty Array' do
          expect(parser).not_to receive(:find_object)

          expect(parser.referenced_by(link)).to eq([])
        end
      end
    end

    context 'when the link does not have a data-project attribute' do
      it 'returns an empty Array' do
        expect(parser.referenced_by(link)).to eq([])
      end
    end
  end

  describe '#find_object' do
    context 'when the project has a valid repository' do
      it 'returns a commit' do
        commit = double(:commit)

        expect(project).to receive(:valid_repo?).and_return(true)
        expect(project).to receive(:commit).with('123').and_return(commit)

        expect(parser.find_object(project, '123')).to eq(commit)
      end
    end

    context 'when the project does not have a valid repository' do
      it 'returns nil' do
        expect(project).to receive(:valid_repo?).and_return(false)

        expect(parser.find_object(project, '123')).to be_nil
      end
    end
  end
end
