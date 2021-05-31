# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::ReferenceParser::CommitParser do
  include ReferenceParserHelpers

  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }
  subject { described_class.new(Banzai::RenderContext.new(project, user)) }

  let(:link) { empty_html_link }

  describe '#nodes_visible_to_user' do
    context 'when the link has a data-issue attribute' do
      before do
        link['data-commit'] = 123
      end

      it_behaves_like "referenced feature visibility", "repository"
    end
  end

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

          allow_next_instance_of(Project) do |instance|
            allow(instance).to receive(:valid_repo?).and_return(true)
          end

          expect(subject).to receive(:find_commits)
            .with(project, ['123'])
            .and_return([commit])

          expect(subject.referenced_by([link])).to eq([commit])
        end

        it 'returns an empty Array when the commit could not be found' do
          allow_next_instance_of(Project) do |instance|
            allow(instance).to receive(:valid_repo?).and_return(true)
          end

          expect(subject).to receive(:find_commits)
            .with(project, ['123'])
            .and_return([])

          expect(subject.referenced_by([link])).to eq([])
        end

        it 'skips projects without valid repositories' do
          allow_next_instance_of(Project) do |instance|
            allow(instance).to receive(:valid_repo?).and_return(false)
          end

          expect(subject.referenced_by([link])).to eq([])
        end
      end

      context 'when the link does not have a data-commit attribute' do
        it 'returns an empty Array' do
          allow_next_instance_of(Project) do |instance|
            allow(instance).to receive(:valid_repo?).and_return(true)
          end

          expect(subject.referenced_by([link])).to eq([])
        end
      end
    end

    context 'when the link does not have a data-project attribute' do
      it 'returns an empty Array' do
        allow_next_instance_of(Project) do |instance|
          allow(instance).to receive(:valid_repo?).and_return(true)
        end

        expect(subject.referenced_by([link])).to eq([])
      end
    end
  end

  describe '#commit_ids_per_project' do
    before do
      link['data-project'] = project.id.to_s
    end

    it 'returns a Hash containing commit IDs per project' do
      link['data-commit'] = '123'

      hash = subject.commit_ids_per_project([link])

      expect(hash).to be_an_instance_of(Hash)

      expect(hash[project.id].to_a).to eq(['123'])
    end

    it 'does not add a project when the data-commit attribute is empty' do
      hash = subject.commit_ids_per_project([link])

      expect(hash).to be_empty
    end
  end

  describe '#find_commits' do
    it 'returns an Array of commit objects' do
      commit = double(:commit)

      expect(project).to receive(:commit).with('123').and_return(commit)
      expect(project).to receive(:valid_repo?).and_return(true)

      expect(subject.find_commits(project, %w{123})).to eq([commit])
    end

    it 'skips commit IDs for which no commit could be found' do
      expect(project).to receive(:commit).with('123').and_return(nil)
      expect(project).to receive(:valid_repo?).and_return(true)

      expect(subject.find_commits(project, %w{123})).to eq([])
    end
  end

  context 'when checking commits on another projects' do
    let!(:control_links) do
      [commit_link]
    end

    let!(:actual_links) do
      control_links + [commit_link, commit_link]
    end

    def commit_link
      project = create(:project, :repository, :public)

      Nokogiri::HTML.fragment(%Q{<a data-commit="#{project.commit.id}" data-project="#{project.id}"></a>}).children[0]
    end

    it_behaves_like 'no project N+1 queries'
  end
end
