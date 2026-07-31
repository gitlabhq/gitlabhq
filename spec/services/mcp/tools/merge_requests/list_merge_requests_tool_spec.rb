# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::MergeRequests::ListMergeRequestsTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:milestone) { create(:milestone, project: project, title: 'v1') }
  let_it_be(:label) { create(:label, project: project, title: 'bug') }

  let_it_be(:mr_by_user) do
    create(:merge_request, source_project: project, target_project: project, source_branch: 'feature-a',
      author: user, milestone: milestone, labels: [label])
  end

  let_it_be(:mr_by_other) do
    create(:merge_request, :closed, source_project: project, target_project: project, source_branch: 'feature-b',
      author: other_user)
  end

  let(:params) { { project_id: project.id.to_s } }
  let(:tool) { described_class.new(current_user: user, params: params) }

  def result_iids(result)
    result[:structuredContent]['nodes'].map { |node| node['iid'] }
  end

  before_all do
    project.add_developer(user)
  end

  describe 'versioning' do
    it 'registers version 0.1.0' do
      expect(tool.version).to eq(Mcp::Tools::Concerns::Constants::VERSIONS[:v0_1_0])
    end

    it 'reads the project root field' do
      expect(tool.operation_name).to eq('project')
    end
  end

  describe '#build_variables' do
    it 'resolves the project and applies the default page size', :aggregate_failures do
      variables = tool.build_variables

      expect(variables[:fullPath]).to eq(project.full_path)
      expect(variables[:first]).to eq(20)
    end

    it 'omits filters that are not provided', :aggregate_failures do
      variables = tool.build_variables

      expect(variables).not_to have_key(:authorUsername)
      expect(variables).not_to have_key(:labelName)
      expect(variables).not_to have_key(:after)
    end

    context 'with filters and pagination' do
      let(:params) do
        super().merge(
          author_username: 'alice',
          reviewer_username: 'bob',
          state: 'opened',
          milestone: 'v1',
          labels: 'bug, urgent ,',
          search: 'dark mode',
          first: 25,
          after: 'cursor1'
        )
      end

      it 'maps them to GraphQL variables', :aggregate_failures do
        variables = tool.build_variables

        expect(variables[:authorUsername]).to eq('alice')
        expect(variables[:reviewerUsername]).to eq('bob')
        expect(variables[:state]).to eq('opened')
        expect(variables[:milestoneTitle]).to eq('v1')
        expect(variables[:labelName]).to eq(%w[bug urgent])
        expect(variables[:search]).to eq('dark mode')
        expect(variables[:first]).to eq(25)
        expect(variables[:after]).to eq('cursor1')
      end
    end

    describe 'scope emulation' do
      context 'when scope is created_by_me' do
        let(:params) { super().merge(scope: 'created_by_me') }

        it 'filters by the current user as author' do
          expect(tool.build_variables[:authorUsername]).to eq(user.username)
        end
      end

      context 'when scope is assigned_to_me' do
        let(:params) { super().merge(scope: 'assigned_to_me') }

        it 'filters by the current user as assignee' do
          expect(tool.build_variables[:assigneeUsername]).to eq(user.username)
        end
      end

      context 'when scope is review_requested' do
        let(:params) { super().merge(scope: 'review_requested') }

        it 'filters by the current user as reviewer' do
          expect(tool.build_variables[:reviewerUsername]).to eq(user.username)
        end
      end

      context 'when no scope is provided' do
        it 'does not add author or assignee filters', :aggregate_failures do
          variables = tool.build_variables

          expect(variables).not_to have_key(:authorUsername)
          expect(variables).not_to have_key(:assigneeUsername)
        end
      end

      context 'when an explicit username is given alongside scope' do
        let(:params) { super().merge(scope: 'created_by_me', author_username: 'explicit') }

        it 'lets the explicit username win' do
          expect(tool.build_variables[:authorUsername]).to eq('explicit')
        end
      end

      context 'when scope targets a different field than the explicit username' do
        let(:params) { super().merge(scope: 'assigned_to_me', author_username: 'explicit') }

        it 'applies both, since precedence is per field', :aggregate_failures do
          variables = tool.build_variables

          expect(variables[:authorUsername]).to eq('explicit')
          expect(variables[:assigneeUsername]).to eq(user.username)
        end
      end
    end

    describe 'project identification' do
      context 'when no project is provided' do
        let(:params) { {} }

        it 'raises an ArgumentError' do
          expect { tool.build_variables }.to raise_error(ArgumentError, /Provide exactly one of/)
        end
      end

      context 'when both url and project_id are provided' do
        let(:params) { { url: project.web_url, project_id: project.id.to_s } }

        it 'raises an ArgumentError rather than silently picking one' do
          expect { tool.build_variables }.to raise_error(ArgumentError, /Provide exactly one of/)
        end
      end

      context 'with a project URL' do
        let(:params) { { url: project.web_url } }

        it 'resolves the project from the URL' do
          expect(tool.build_variables[:fullPath]).to eq(project.full_path)
        end
      end

      context 'with a full path' do
        let(:params) { { project_id: project.full_path } }

        it 'resolves the project from the path' do
          expect(tool.build_variables[:fullPath]).to eq(project.full_path)
        end
      end
    end
  end

  describe 'integration' do
    it 'executes the query as the current user with the resolved variables' do
      allow(GitlabSchema).to receive(:execute).and_call_original

      tool.execute

      expect(GitlabSchema).to have_received(:execute).with(
        anything,
        variables: hash_including(fullPath: project.full_path),
        context: hash_including(current_user: user)
      )
    end

    it 'returns the merge requests connection shaped for agent consumption', :aggregate_failures do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:content].first[:type]).to eq('text')
      expect(result[:structuredContent]).to have_key('pageInfo')
      expect(result[:structuredContent]).to have_key('nodes')
      expect(result_iids(result)).to contain_exactly(mr_by_user.iid.to_s, mr_by_other.iid.to_s)
    end

    it 'does not return an unbounded total count' do
      expect(tool.execute[:structuredContent]).not_to have_key('count')
    end

    describe 'filtering' do
      context 'when filtering by author_username' do
        let(:params) { super().merge(author_username: user.username) }

        it 'returns only the matching merge requests' do
          expect(result_iids(tool.execute)).to contain_exactly(mr_by_user.iid.to_s)
        end
      end

      context 'when filtering by state' do
        let(:params) { super().merge(state: 'closed') }

        it 'returns only merge requests in that state' do
          expect(result_iids(tool.execute)).to contain_exactly(mr_by_other.iid.to_s)
        end
      end

      context 'when filtering by labels' do
        let(:params) { super().merge(labels: label.title) }

        it 'returns only labelled merge requests' do
          expect(result_iids(tool.execute)).to contain_exactly(mr_by_user.iid.to_s)
        end
      end

      context 'when filtering by several labels' do
        let_it_be(:second_label) { create(:label, project: project, title: 'urgent') }

        let(:params) { super().merge(labels: " #{label.title}, #{second_label.title} ,") }

        it 'requires all of them, ignoring whitespace and empty entries' do
          expect(result_iids(tool.execute)).to be_empty
        end

        context 'when a merge request carries both' do
          let_it_be(:both_labels_mr) do
            create(:merge_request, source_project: project, target_project: project,
              source_branch: 'feature-c', labels: [label, second_label])
          end

          it 'returns it' do
            expect(result_iids(tool.execute)).to contain_exactly(both_labels_mr.iid.to_s)
          end
        end
      end

      context 'when filtering by milestone' do
        let(:params) { super().merge(milestone: milestone.title) }

        it 'returns only merge requests in that milestone' do
          expect(result_iids(tool.execute)).to contain_exactly(mr_by_user.iid.to_s)
        end
      end
    end

    describe 'authorization' do
      let_it_be(:non_member) { create(:user) }
      let_it_be(:private_project) { create(:project, :private) }
      let_it_be(:private_mr) do
        create(:merge_request, source_project: private_project, target_project: private_project)
      end

      let(:params) { { project_id: private_project.id.to_s } }

      context 'when the caller is not a member' do
        let(:tool) { described_class.new(current_user: non_member, params: params) }

        it 'denies access rather than listing its merge requests' do
          expect { tool.execute }.to raise_error(ArgumentError, /Access denied to project/)
        end
      end

      context 'when the caller is a member' do
        before_all do
          private_project.add_developer(user)
        end

        it 'returns its merge requests' do
          expect(result_iids(tool.execute)).to contain_exactly(private_mr.iid.to_s)
        end
      end

      context 'when the project does not exist' do
        let(:params) { { project_id: non_existing_record_id.to_s } }

        it 'raises before executing GraphQL' do
          expect { tool.execute }.to raise_error(StandardError, /not found or inaccessible/)
        end
      end
    end

    context 'when GraphQL returns errors' do
      before do
        allow(GitlabSchema).to receive(:execute).and_return({ 'errors' => [{ 'message' => 'Boom' }] })
      end

      it 'surfaces the error message', :aggregate_failures do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Boom')
      end
    end

    context 'when the project resolves but the query returns no data' do
      before do
        allow(GitlabSchema).to receive(:execute).and_return({ 'data' => { 'project' => nil } })
      end

      it 'returns a project-not-found error', :aggregate_failures do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Project not found')
      end
    end
  end
end
