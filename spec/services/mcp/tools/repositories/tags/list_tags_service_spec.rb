# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Repositories::Tags::ListTagsService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :public, maintainers: user) }

  let(:service) { described_class.new(name: 'list_tags') }

  before do
    service.set_cred(current_user: user)
  end

  def execute(arguments)
    service.execute(params: { name: 'list_tags', arguments: arguments })
  end

  def tag_names(result)
    result[:structuredContent][:tags].pluck(:name)
  end

  describe 'class configuration' do
    it 'registers version 0.1.0 as read-only', :aggregate_failures do
      expect(described_class.available_versions).to include('0.1.0')
      expect(described_class.version_metadata('0.1.0')[:annotations]).to eq({ readOnlyHint: true })
    end

    it 'derives the first bounds and description from the constants', :aggregate_failures do
      first = described_class.version_metadata('0.1.0')[:input_schema][:properties][:first]

      expect(first[:maximum]).to eq(described_class::MAX_FIRST)
      expect(first[:description]).to eq('Number of tags to return. Default is 20, maximum is 100.')
    end
  end

  describe '#execute' do
    it 'returns tags most recently updated first', :aggregate_failures do
      result = execute({ project_id: project.full_path })

      expect(result[:isError]).to be false
      expect(tag_names(result)).to eq(%w[v1.1.1 v1.1.0 v1.0.0])
    end

    it 'returns metadata-only entries with the tip commit', :aggregate_failures do
      entry = execute({ project_id: project.full_path })[:structuredContent][:tags].last

      expect(entry.keys).to match_array(%i[name commit])
      expect(entry[:name]).to eq('v1.0.0')
      expect(entry[:commit]).to eq(
        sha: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9',
        title: 'More submodules'
      )
    end

    it 'returns a null commit for a tag that does not point at a commit', :aggregate_failures do
      tag = Gitlab::Git::Tag.new(project.repository,
        { name: 'v-tree', target: '9a944d90955aaf45f6d0c88f30e27f8d2c41cec0', target_commit: nil })

      allow_next_instance_of(TagsFinder) do |finder|
        allow(finder).to receive(:execute).and_return([tag])
      end

      result = execute({ project_id: project.full_path })

      expect(result[:isError]).to be false
      expect(result[:structuredContent][:tags]).to contain_exactly({ name: 'v-tree', commit: nil })
    end

    it 'accepts a numeric project id' do
      expect(tag_names(execute({ project_id: project.id.to_s }))).to eq(%w[v1.1.1 v1.1.0 v1.0.0])
    end

    it 'resolves the project from a url' do
      expect(tag_names(execute({ url: project.web_url }))).to eq(%w[v1.1.1 v1.1.0 v1.0.0])
    end

    describe 'search' do
      it 'filters tags by name' do
        expect(tag_names(execute({ project_id: project.full_path, search: 'v1.1' }))).to eq(%w[v1.1.1 v1.1.0])
      end

      # Filtering happens before slicing, so the cursor must walk the matched set, not all tags.
      it 'paginates within the filtered set', :aggregate_failures do
        first_page = execute({ project_id: project.full_path, search: 'v1.1', first: 1 })

        expect(tag_names(first_page)).to eq(%w[v1.1.1])
        expect(first_page[:structuredContent][:metadata]).to eq(has_next_page: true, end_cursor: 'v1.1.1')

        second_page = execute({ project_id: project.full_path, search: 'v1.1', first: 1, after: 'v1.1.1' })

        expect(tag_names(second_page)).to eq(%w[v1.1.0])
        expect(second_page[:structuredContent][:metadata]).to eq(has_next_page: false, end_cursor: nil)
      end

      it 'rejects a cursor that matches no filtered tag', :aggregate_failures do
        result = execute({ project_id: project.full_path, search: 'v1.1', after: 'v1.0.0' })

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to eq("Validation error: Invalid after cursor: 'v1.0.0'")
      end

      it 'returns an empty list when nothing matches', :aggregate_failures do
        result = execute({ project_id: project.full_path, search: 'nope' })

        expect(result[:isError]).to be false
        expect(result[:structuredContent][:tags]).to eq([])
      end
    end

    describe 'pagination' do
      it 'defaults to 20 tags with no cursor' do
        result = execute({ project_id: project.full_path })

        expect(result[:structuredContent][:metadata]).to eq(has_next_page: false, end_cursor: nil)
      end

      it 'returns an end_cursor while a full page may be followed by more', :aggregate_failures do
        result = execute({ project_id: project.full_path, first: 2 })

        expect(tag_names(result)).to eq(%w[v1.1.1 v1.1.0])
        expect(result[:structuredContent][:metadata]).to eq(has_next_page: true, end_cursor: 'v1.1.0')
      end

      it 'continues after the cursor and clears has_next_page on a short page', :aggregate_failures do
        result = execute({ project_id: project.full_path, first: 2, after: 'v1.1.0' })

        expect(tag_names(result)).to eq(%w[v1.0.0])
        expect(result[:structuredContent][:metadata]).to eq(has_next_page: false, end_cursor: nil)
      end

      # Gitaly caps the fetch at `first`, so a full final page cannot be told apart from a partial one.
      it 'returns an empty page after a full final page', :aggregate_failures do
        full_final = execute({ project_id: project.full_path, first: 3 })

        expect(full_final[:structuredContent][:metadata]).to eq(has_next_page: true, end_cursor: 'v1.0.0')

        result = execute({ project_id: project.full_path, first: 3, after: 'v1.0.0' })

        expect(result[:isError]).to be false
        expect(result[:structuredContent][:tags]).to eq([])
        expect(result[:structuredContent][:metadata]).to eq(has_next_page: false, end_cursor: nil)
      end

      it 'rejects a cursor that names no tag', :aggregate_failures do
        result = execute({ project_id: project.full_path, after: 'no-such-tag' })

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to eq("Validation error: Invalid after cursor: 'no-such-tag'")
      end

      it 'accepts both first boundaries', :aggregate_failures do
        expect(execute({ project_id: project.full_path, first: 1 })[:isError]).to be false
        expect(execute({ project_id: project.full_path, first: 100 })[:isError]).to be false
      end

      it 'rejects first below the minimum' do
        expect(execute({ project_id: project.full_path, first: 0 })[:isError]).to be true
      end

      it 'rejects first above the maximum', :aggregate_failures do
        result = execute({ project_id: project.full_path, first: 101 })

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('first')
      end
    end

    describe 'gitaly pagination' do
      it 'lets Gitaly limit an unfiltered page', :aggregate_failures do
        expect_next_instance_of(TagsFinder) do |finder|
          expect(finder).to receive(:execute).with(gitaly_pagination: true).and_call_original
        end

        expect(tag_names(execute({ project_id: project.full_path, first: 2 }))).to eq(%w[v1.1.1 v1.1.0])
      end

      it 'lets Gitaly limit an unfiltered page after a cursor', :aggregate_failures do
        expect_next_instance_of(TagsFinder) do |finder|
          expect(finder).to receive(:execute).with(gitaly_pagination: true).and_call_original
        end

        expect(tag_names(execute({ project_id: project.full_path, first: 2, after: 'v1.1.1' })))
          .to eq(%w[v1.1.0 v1.0.0])
      end

      it 'fetches every tag when a search is given', :aggregate_failures do
        expect_next_instance_of(TagsFinder) do |finder|
          expect(finder).to receive(:execute).with(no_args).and_call_original
        end

        expect(tag_names(execute({ project_id: project.full_path, search: 'v1.1' }))).to eq(%w[v1.1.1 v1.1.0])
      end
    end

    describe 'project identification' do
      it 'resolves each call against its own project', :aggregate_failures do
        other = create(:project, :repository, :public, maintainers: user)
        other.repository.add_tag(user, 'v9.9', 'master')

        first = tag_names(execute({ project_id: project.full_path }))
        second = tag_names(execute({ project_id: other.full_path }))

        expect(first).not_to include('v9.9')
        expect(second).to include('v9.9')
      end

      it 'rejects neither identifier', :aggregate_failures do
        result = execute({})

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('Provide exactly one of: url or project_id')
      end

      it 'rejects a call without arguments' do
        result = service.execute(params: { name: 'list_tags' })

        expect(result[:content].first[:text]).to include('Provide exactly one of: url or project_id')
      end

      it 'rejects both identifiers' do
        result = execute({ url: project.web_url, project_id: project.full_path })

        expect(result[:content].first[:text]).to include('Provide exactly one of: url or project_id')
      end

      it 'reports a url pointing at a project that does not exist' do
        expect(execute({ url: 'https://gitlab.com/no/such-project-xyz' })[:content].first[:text])
          .to include('not found or inaccessible')
      end

      # BaseService strips empty strings, so a blank identifier reads as omitted rather than
      # as a project named "".
      it 'treats an empty project_id as absent' do
        expect(execute({ project_id: '' })[:content].first[:text])
          .to include('Provide exactly one of: url or project_id')
      end

      it 'rejects a url pointing at a group', :aggregate_failures do
        group = create(:group, :public)

        result = execute({ url: group.web_url })

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('must point to a project')
      end
    end

    describe 'schema validation' do
      it 'rejects project_id given as an integer', :aggregate_failures do
        result = execute({ project_id: project.id })

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('project_id is invalid')
      end

      it 'rejects a non-integer first' do
        expect(execute({ project_id: project.full_path, first: '2' })[:content].first[:text])
          .to include('first is invalid')
      end

      it 'rejects a non-string after' do
        expect(execute({ project_id: project.full_path, after: 2 })[:content].first[:text])
          .to include('after is invalid')
      end

      it 'rejects a non-string search' do
        expect(execute({ project_id: project.full_path, search: 5 })[:content].first[:text])
          .to include('search is invalid')
      end

      # SchemaDefaults applies additionalProperties: false, so an argument the tool does not
      # declare is refused rather than silently ignored.
      it 'rejects an argument the schema does not declare', :aggregate_failures do
        result = execute({ project_id: project.full_path, sort: 'asc' })

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('sort is invalid')
      end

      it 'advertises additionalProperties: false' do
        expect(service.input_schema[:additionalProperties]).to be(false)
      end
    end

    it 'looks the project up once when an optional argument is sent as null' do
      expect(service).to receive(:find_project!).once.and_call_original

      execute({ project_id: project.full_path, search: nil })
    end

    context 'when the project has no repository' do
      let_it_be(:empty_project) { create(:project, :public, maintainers: user) }

      it 'returns an empty list rather than failing', :aggregate_failures do
        result = execute({ project_id: empty_project.full_path })

        expect(result[:isError]).to be false
        expect(result[:structuredContent][:tags]).to eq([])
      end
    end

    context 'when the caller cannot read the project' do
      let_it_be(:other_user) { create(:user) }
      let_it_be(:private_project) { create(:project, :repository, :private) }

      # A fresh service per call: the real server builds one per request, and reusing a
      # single instance would compare its memoized project lookup against itself.
      def execute_isolated(arguments)
        described_class.new(name: 'list_tags')
          .tap { |svc| svc.set_cred(current_user: other_user) }
          .execute(params: { name: 'list_tags', arguments: arguments })
      end

      # Both answers use the same template, so a caller cannot tell whether a project they
      # cannot see exists. The identifier differs only because the caller supplied it.
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
      before do
        service.set_cred(current_user: nil)
      end

      it 'returns an error' do
        expect(execute({ project_id: project.full_path })[:isError]).to be true
      end
    end
  end
end
