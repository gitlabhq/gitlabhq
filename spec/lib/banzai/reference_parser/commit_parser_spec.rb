# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::ReferenceParser::CommitParser, feature_category: :source_code_management do
  include ReferenceParserHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { create(:user) }

  subject { described_class.new(Banzai::RenderContext.new(project, user)) }

  let(:link) { empty_html_link }

  describe '#nodes_visible_to_user' do
    context 'when the link has a data-project attribute' do
      before do
        link['data-project'] = project.id.to_s
      end

      it_behaves_like "referenced feature visibility", "repository"

      it 'includes the link if can_read_reference? returns true' do
        expect(subject).to receive(:can_read_reference?).with(user, project, link).and_return(true)

        expect(subject.nodes_visible_to_user(user, [link])).to contain_exactly(link)
      end

      it 'excludes the link if can_read_reference? returns false' do
        expect(subject).to receive(:can_read_reference?).with(user, project, link).and_return(false)

        expect(subject.nodes_visible_to_user(user, [link])).to be_empty
      end
    end

    context 'when the link does not have a data-project attribute' do
      it 'returns the nodes' do
        expect(subject.nodes_visible_to_user(user, [link])).to eq([link])
      end
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
    let_it_be(:ids) { project.repository.commits(project.default_branch, limit: 3).map(&:id) }

    it 'is empty when repo is invalid' do
      allow(project).to receive(:valid_repo?).and_return(false)

      expect(subject.find_commits(project, ids)).to eq([])
    end

    it 'returns commits by the specified ids' do
      expect(subject.find_commits(project, ids).map(&:id)).to eq(%w[
        b83d6e391c22777fca1ed3012fce84f633d7fed0
        498214de67004b1da3d820901307bed2a68a8ef6
        1b12f15a11fc6e62177bef08f47bc7b5ce50b141
      ])
    end

    it 'is limited' do
      stub_const("#{described_class}::COMMITS_LIMIT", 1)

      expect(subject.find_commits(project, ids).map(&:id)).to eq([
        "b83d6e391c22777fca1ed3012fce84f633d7fed0"
      ])
    end
  end

  context 'when checking commits on another projects', :request_store do
    let!(:control_links) do
      [commit_link]
    end

    let!(:actual_links) do
      control_links + [commit_link, commit_link]
    end

    def commit_link
      project = create(:project, :repository, :public)

      Nokogiri::HTML.fragment(%(<a data-commit="#{project.commit.id}" data-project="#{project.id}"></a>)).children[0]
    end

    it_behaves_like 'no project N+1 queries'
  end
end
