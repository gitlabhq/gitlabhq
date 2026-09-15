# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Releases::ListReleasesService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, freeze: false) { create(:project, :public, maintainers: [user]) }

  let_it_be(:release_v1) { create(:release, project: project, tag: 'v1.0', released_at: 3.days.ago) }
  let_it_be(:release_v2, freeze: false) { create(:release, project: project, tag: 'v2.0', released_at: 2.days.ago) }
  let_it_be(:release_v3, freeze: false) do
    create(:release, project: project, tag: 'v3.0', released_at: 1.day.ago)
  end

  let(:service) { described_class.new(name: 'list_releases') }

  before do
    service.set_cred(current_user: user)
  end

  def execute(arguments)
    service.execute(params: { name: 'list_releases', arguments: arguments })
  end

  describe 'class configuration' do
    it 'registers version 0.1.0 as read-only', :aggregate_failures do
      expect(described_class.available_versions).to include('0.1.0')
      expect(described_class.version_metadata('0.1.0')[:annotations]).to eq({ readOnlyHint: true })
    end

    it 'locks the full input schema for version 0.1.0' do
      expect(described_class.version_metadata('0.1.0')[:input_schema]).to eq({
        type: 'object',
        required: [],
        properties: {
          url: {
            type: 'string',
            description: 'GitLab URL of the project.'
          },
          project_id: {
            type: 'string',
            description: 'ID or full path of the project.'
          },
          page: {
            type: 'integer',
            minimum: 1,
            description: 'Page number to retrieve. Default is 1.'
          },
          per_page: {
            type: 'integer',
            minimum: 1,
            maximum: 100,
            description: 'Releases to return per page. Default is 20, maximum is 100.'
          },
          state: {
            type: 'string',
            description: 'Filter by release state. released covers releases already out, ' \
              'upcoming covers releases scheduled for a future date. Default is released.',
            enum: %w[released upcoming all]
          }
        }
      })
    end
  end

  describe '#execute' do
    it 'returns releases most recently released first', :aggregate_failures do
      result = execute({ project_id: project.full_path })

      expect(result[:isError]).to be false
      expect(result[:structuredContent][:releases].pluck(:tag_name)).to eq(%w[v3.0 v2.0 v1.0])
    end

    it 'returns metadata-only entries' do
      result = execute({ project_id: project.full_path })

      expect(result[:structuredContent][:releases].first.keys)
        .to match_array(%i[tag_name name released_at upcoming assets])
    end

    it 'accepts a numeric project id' do
      result = execute({ project_id: project.id.to_s })

      expect(result[:structuredContent][:releases].pluck(:tag_name)).to eq(%w[v3.0 v2.0 v1.0])
    end

    it 'resolves the project from a url' do
      result = execute({ url: project.web_url })

      expect(result[:structuredContent][:releases].pluck(:tag_name)).to eq(%w[v3.0 v2.0 v1.0])
    end

    context 'with asset links' do
      let_it_be(:link) do
        create(:release_link, release: release_v3, name: 'Binary', url: 'https://example.com/binary')
      end

      it 'exposes asset links, excluding source archives' do
        result = execute({ project_id: project.full_path })

        expect(result[:structuredContent][:releases].first[:assets]).to eq(
          count: 1,
          links: [{ name: 'Binary', url: 'https://example.com/binary' }]
        )
      end

      it 'caps the links and reports the real total', :aggregate_failures do
        extra = described_class::MAX_ASSET_LINKS + 2
        (1..extra).each do |i|
          create(:release_link, release: release_v2, name: "asset-#{i}", url: "https://example.com/a#{i}")
        end

        assets = execute({ project_id: project.full_path })[:structuredContent][:releases]
          .find { |r| r[:tag_name] == 'v2.0' }[:assets]

        expect(assets[:count]).to eq(extra)
        expect(assets[:links].size).to eq(described_class::MAX_ASSET_LINKS)
      end
    end

    describe 'upcoming releases' do
      # Releases with a future date sort to the top. An agent asking for the latest release
      # would get one that is not published yet.
      let_it_be(:scheduled) do
        create(:release, project: project, tag: 'v9.0-rc', released_at: 30.days.from_now)
      end

      it 'omits scheduled releases by default', :aggregate_failures do
        result = execute({ project_id: project.full_path })

        expect(result[:structuredContent][:releases].pluck(:tag_name)).not_to include('v9.0-rc')
        expect(result[:structuredContent][:releases].pluck(:upcoming)).to all(be false)
      end

      it 'omits scheduled releases when state is released' do
        result = execute({ project_id: project.full_path, state: 'released' })

        expect(result[:structuredContent][:releases].pluck(:tag_name)).to eq(%w[v3.0 v2.0 v1.0])
      end

      it 'returns only scheduled releases when state is upcoming', :aggregate_failures do
        result = execute({ project_id: project.full_path, state: 'upcoming' })

        expect(result[:structuredContent][:releases].pluck(:tag_name)).to eq(%w[v9.0-rc])
        expect(result[:structuredContent][:releases].first[:upcoming]).to be true
      end

      it 'returns both when state is all', :aggregate_failures do
        result = execute({ project_id: project.full_path, state: 'all' })

        expect(result[:structuredContent][:releases].pluck(:tag_name)).to eq(%w[v9.0-rc v3.0 v2.0 v1.0])
        expect(result[:structuredContent][:releases].pluck(:upcoming)).to eq([true, false, false, false])
      end

      it 'rejects a state outside the enum' do
        expect(execute({ project_id: project.full_path, state: 'nope' })[:content].first[:text])
          .to include('state')
      end

      it 'excludes them from the paginated count, not just the page', :aggregate_failures do
        result = execute({ project_id: project.full_path, per_page: 3 })

        expect(result[:structuredContent][:releases].pluck(:tag_name)).to eq(%w[v3.0 v2.0 v1.0])
        expect(result[:structuredContent][:metadata][:has_more]).to be false
      end
    end

    describe 'pagination' do
      it 'defaults to page 1 with 20 per page' do
        result = execute({ project_id: project.full_path })

        expect(result[:structuredContent][:metadata]).to eq(page: 1, per_page: 20, has_more: false)
      end

      it 'signals has_more while pages remain', :aggregate_failures do
        result = execute({ project_id: project.full_path, per_page: 2 })

        expect(result[:structuredContent][:releases].pluck(:tag_name)).to eq(%w[v3.0 v2.0])
        expect(result[:structuredContent][:metadata]).to eq(page: 1, per_page: 2, has_more: true)
      end

      it 'clears has_more on the final page', :aggregate_failures do
        result = execute({ project_id: project.full_path, per_page: 2, page: 2 })

        expect(result[:structuredContent][:releases].pluck(:tag_name)).to eq(%w[v1.0])
        expect(result[:structuredContent][:metadata]).to eq(page: 2, per_page: 2, has_more: false)
      end

      it 'returns an empty page past the end', :aggregate_failures do
        result = execute({ project_id: project.full_path, page: 99 })

        expect(result[:isError]).to be false
        expect(result[:structuredContent][:releases]).to eq([])
        expect(result[:structuredContent][:metadata][:has_more]).to be false
      end

      it 'rejects per_page above the maximum', :aggregate_failures do
        result = execute({ project_id: project.full_path, per_page: 101 })

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('per_page')
      end

      it 'rejects a page below 1' do
        result = execute({ project_id: project.full_path, page: 0 })

        expect(result[:isError]).to be true
      end
    end

    describe 'project identification' do
      it 'rejects neither identifier', :aggregate_failures do
        result = execute({})

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('Provide exactly one of: url or project_id')
      end

      it 'rejects a call without arguments', :aggregate_failures do
        result = service.execute(params: { name: 'list_releases' })

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('Provide exactly one of: url or project_id')
      end

      it 'rejects both identifiers' do
        result = execute({ url: project.web_url, project_id: project.full_path })

        expect(result[:content].first[:text]).to include('Provide exactly one of: url or project_id')
      end

      it 'rejects a url pointing at a group', :aggregate_failures do
        group = create(:group, :public)

        result = execute({ url: group.web_url })

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('must point to a project')
      end
    end

    context 'when the project has no releases' do
      let_it_be(:empty_project) { create(:project, :public, maintainers: [user]) }

      it 'returns an empty list', :aggregate_failures do
        result = execute({ project_id: empty_project.full_path })

        expect(result[:isError]).to be false
        expect(result[:structuredContent][:releases]).to eq([])
      end
    end

    context 'when the caller cannot read the project' do
      let_it_be(:other_user) { create(:user) }
      let_it_be(:private_project, freeze: false) { create(:project, :private) }
      let_it_be(:private_release) { create(:release, project: private_project, tag: 'v1.0') }

      # A fresh service per call: the real server builds one per request, and reusing a
      # single instance would compare its memoized project lookup against itself.
      def execute_isolated(arguments)
        described_class.new(name: 'list_releases')
          .tap { |svc| svc.set_cred(current_user: other_user) }
          .execute(params: { name: 'list_releases', arguments: arguments })
      end

      it 'answers a private project exactly as it answers a missing one', :aggregate_failures do
        denied = execute_isolated({ project_id: private_project.full_path })
        missing = execute_isolated({ project_id: 'no/such-project' })

        expect(denied[:isError]).to be true
        expect(denied[:content].first[:text])
          .to eq("Tool execution failed: Project '#{private_project.full_path}' not found or inaccessible")
        expect(missing[:content].first[:text])
          .to eq("Tool execution failed: Project 'no/such-project' not found or inaccessible")
      end
    end

    context 'when no current_user is set' do
      let(:service) { described_class.new(name: 'list_releases') }

      before do
        service.set_cred(current_user: nil)
      end

      it 'returns an error' do
        result = execute({ project_id: project.full_path })

        expect(result[:isError]).to be true
      end
    end
  end
end
