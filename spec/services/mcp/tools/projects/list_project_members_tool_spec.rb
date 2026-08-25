# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Projects::ListProjectMembersTool, feature_category: :mcp_server do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:maintainer) { create(:user, username: 'zoe-maintainer', name: 'Zoe Maintainer') }
  let_it_be(:guest) { create(:user, username: 'ana-guest', name: 'Ana Guest') }
  let_it_be(:inherited_developer) { create(:user, username: 'ida-developer', name: 'Ida Developer') }

  let(:params) { { project_id: project.id.to_s } }
  let(:tool) { described_class.new(current_user: maintainer, params: params) }

  before_all do
    project.add_maintainer(maintainer)
    project.add_member(guest, :guest, expires_at: '2035-01-01')
    group.add_developer(inherited_developer)
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
    it 'resolves the project from its numeric ID and defaults to direct members' do
      expect(tool.build_variables).to eq({
        fullPath: project.full_path,
        relations: %w[DIRECT],
        first: described_class::DEFAULT_PAGE_SIZE
      })
    end

    context 'with a full path' do
      let(:params) { { project_id: project.full_path } }

      it 'resolves the project from the path' do
        expect(tool.build_variables[:fullPath]).to eq(project.full_path)
      end
    end

    context 'with include_inherited' do
      let(:params) { { project_id: project.id.to_s, include_inherited: true } }

      it 'widens the relations filter' do
        expect(tool.build_variables[:relations]).to eq(%w[DIRECT INHERITED DESCENDANTS])
      end
    end

    context 'with a query and pagination arguments' do
      let(:params) { { project_id: project.id.to_s, query: 'zoe', first: 5, after: 'cursor' } }

      it 'maps them onto the GraphQL arguments' do
        expect(tool.build_variables).to include(search: 'zoe', first: 5, after: 'cursor')
      end
    end

    context 'when the project does not exist' do
      let(:params) { { project_id: non_existing_record_id.to_s } }

      it 'raises before executing GraphQL' do
        expect { tool.build_variables }.to raise_error(StandardError, /not found or inaccessible/)
      end
    end
  end

  describe 'integration' do
    it 'executes the query as the current user with the resolved variables' do
      allow(GitlabSchema).to receive(:execute).and_call_original

      tool.execute

      expect(GitlabSchema).to have_received(:execute).with(
        anything,
        variables: { fullPath: project.full_path, relations: %w[DIRECT],
                     first: described_class::DEFAULT_PAGE_SIZE },
        context: hash_including(current_user: maintainer)
      )
    end

    it 'returns direct members shaped for agent consumption', :aggregate_failures do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:content].first[:type]).to eq('text')
      expect(result[:structuredContent][:items]).to contain_exactly(
        {
          id: maintainer.id,
          username: 'zoe-maintainer',
          name: 'Zoe Maintainer',
          access_level: Gitlab::Access::MAINTAINER,
          access_level_name: 'Maintainer',
          expires_at: nil
        },
        {
          id: guest.id,
          username: 'ana-guest',
          name: 'Ana Guest',
          access_level: Gitlab::Access::GUEST,
          access_level_name: 'Guest',
          expires_at: '2035-01-01'
        }
      )
    end

    it 'returns pagination metadata' do
      expect(tool.execute[:structuredContent][:metadata])
        .to match({ has_next_page: false, end_cursor: be_present })
    end

    context 'with include_inherited' do
      let(:params) { { project_id: project.id.to_s, include_inherited: true } }

      it 'also returns members inherited from the parent group' do
        expect(tool.execute[:structuredContent][:items].pluck(:username)).to include('ida-developer')
      end
    end

    context 'without include_inherited' do
      it 'omits members inherited from the parent group' do
        expect(tool.execute[:structuredContent][:items].pluck(:username)).not_to include('ida-developer')
      end
    end

    context 'with a query filter' do
      let(:params) { { project_id: project.id.to_s, query: 'ana' } }

      it 'returns only the matching members' do
        expect(tool.execute[:structuredContent][:items].pluck(:username)).to contain_exactly('ana-guest')
      end
    end

    context 'with pagination' do
      let(:params) { { project_id: project.id.to_s, first: 1 } }

      it 'limits the page and reports the next cursor', :aggregate_failures do
        result = tool.execute
        metadata = result[:structuredContent][:metadata]

        expect(result[:structuredContent][:items].size).to eq(1)
        expect(metadata[:has_next_page]).to be(true)
        expect(metadata[:end_cursor]).to be_present
      end

      it 'returns the following page for the returned cursor' do
        first_page = tool.execute
        cursor = first_page[:structuredContent][:metadata][:end_cursor]

        next_page = described_class.new(
          current_user: maintainer,
          params: { project_id: project.id.to_s, first: 1, after: cursor }
        ).execute

        expect(next_page[:structuredContent][:items]).not_to eq(first_page[:structuredContent][:items])
      end
    end

    context 'when the project has no members matching the filters' do
      let(:params) { { project_id: project.id.to_s, query: 'nobody-by-that-name' } }

      it 'returns an empty list rather than an error', :aggregate_failures do
        result = tool.execute

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent][:items]).to eq([])
      end
    end

    context 'when a member has no user yet' do
      before do
        create(:project_member, :invited, project: project, invite_email: build_stubbed(:user).email)
      end

      it 'skips the pending invitation' do
        expect(tool.execute[:structuredContent][:items].pluck(:username))
          .to contain_exactly('zoe-maintainer', 'ana-guest')
      end
    end

    context 'when the project is not visible to the caller' do
      let_it_be(:private_project) { create(:project, :private) }

      let(:params) { { project_id: private_project.id.to_s } }

      it 'raises before executing GraphQL' do
        expect { tool.execute }.to raise_error(StandardError, /not found or inaccessible/)
      end
    end

    context 'when the caller cannot read the project members' do
      let_it_be(:non_member) { create(:user) }

      let(:tool) { described_class.new(current_user: non_member, params: params) }

      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(non_member, :read_project_member, anything).and_return(false)
      end

      it 'returns an access denied error', :aggregate_failures do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('you do not have permission to list the members')
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
  end
end
