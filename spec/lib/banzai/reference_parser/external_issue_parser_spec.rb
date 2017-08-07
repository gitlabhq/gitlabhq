require 'spec_helper'

describe Banzai::ReferenceParser::ExternalIssueParser do
  include ReferenceParserHelpers

  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }
  subject { described_class.new(project, user) }
  let(:link) { empty_html_link }

  describe '#nodes_visible_to_user' do
    context 'when the link has a data-issue attribute' do
      before do
        link['data-external-issue'] = 123
      end

      levels = [ProjectFeature::DISABLED, ProjectFeature::PRIVATE, ProjectFeature::ENABLED]

      levels.each do |level|
        it "creates reference when the feature is #{level}" do
          project.project_feature.update(issues_access_level: level)

          visible_nodes = subject.nodes_visible_to_user(user, [link])

          expect(visible_nodes).to include(link)
        end
      end
    end
  end

  describe '#referenced_by' do
    context 'when the link has a data-project attribute' do
      before do
        link['data-project'] = project.id.to_s
      end

      context 'when the link has a data-external-issue attribute' do
        it 'returns an Array of ExternalIssue instances' do
          link['data-external-issue'] = '123'

          refs = subject.referenced_by([link])

          expect(refs).to eq([ExternalIssue.new('123', project)])
        end
      end

      context 'when the link does not have a data-external-issue attribute' do
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

  describe '#issue_ids_per_project' do
    before do
      link['data-project'] = project.id.to_s
    end

    it 'returns a Hash containing range IDs per project' do
      link['data-external-issue'] = '123'

      hash = subject.issue_ids_per_project([link])

      expect(hash).to be_an_instance_of(Hash)

      expect(hash[project.id].to_a).to eq(['123'])
    end

    it 'does not add a project when the data-external-issue attribute is empty' do
      hash = subject.issue_ids_per_project([link])

      expect(hash).to be_empty
    end
  end
end
