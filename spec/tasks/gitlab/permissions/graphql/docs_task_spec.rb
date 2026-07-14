# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tasks::Gitlab::Permissions::Graphql::DocsTask, :silence_stdout, feature_category: :permissions do
  let(:task) { described_class.new }
  let(:path) { Rails.root.join('tmp/tests/doc/gitlab/permissions/graphql/') }
  let(:doc) { 'granular_pat_graphql_fields.md' }
  let(:doc_path) { Rails.root.join(path, doc) }

  let(:vulnerability_type) { mock_type('Vulnerability', directive: directive(:read_vulnerability)) }
  let(:project_type) do
    mock_type('ProjectType', fields: { 'pipelines' => mock_field(directive: directive(:read_pipeline)) })
  end

  let(:mutation_type) do
    resolver = mock_resolver(graphql_name: 'VulnerabilityCreate')
    field = mock_mutation_field(resolver: resolver, directive: directive(:create_vulnerability))
    mutation_type_with_fields('vulnerabilityCreate' => field)
  end

  let(:vulnerability_assignable) do
    instance_double(::Authz::PermissionGroups::Assignable,
      category_name: 'Application Security',
      resource_name: 'Vulnerability',
      resource_description: 'Grants the ability to create and read vulnerabilities',
      action: 'read'
    )
  end

  let(:create_vulnerability_assignable) do
    instance_double(::Authz::PermissionGroups::Assignable,
      category_name: 'Application Security',
      resource_name: 'Vulnerability',
      resource_description: 'Grants the ability to create and read vulnerabilities',
      action: 'create'
    )
  end

  let(:pipeline_assignable) do
    instance_double(::Authz::PermissionGroups::Assignable,
      category_name: 'CI/CD',
      resource_name: 'Pipeline',
      resource_description: 'Grants the ability to read pipelines',
      action: 'read'
    )
  end

  before do
    allow(GitlabSchema).to receive(:types).and_return(
      'Vulnerability' => vulnerability_type,
      'ProjectType' => project_type,
      'Mutation' => mutation_type
    )

    allow(::Authz::PermissionGroups::Assignable).to receive(:available_for_permission).and_return([])
    allow(::Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
      .with(:read_vulnerability).and_return([vulnerability_assignable])
    allow(::Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
      .with(:create_vulnerability).and_return([create_vulnerability_assignable])
    allow(::Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
      .with(:read_pipeline).and_return([pipeline_assignable])
  end

  describe '#allowed_fields' do
    # 1. Categories are sorted alphabetically (Application Security before CI/CD)
    # 2. Resources are sorted alphabetically
    # 3. Rows are sorted by action, then boundary (BOUNDARY_SORT_ORDER), then kind (KIND_SORT_ORDER)
    let(:expected_markdown) do
      <<~MARKDOWN.chomp
        ### Application Security resources

        #### Vulnerability

        Grants the ability to create and read vulnerabilities

        | Action | Access | Kind | Name |
        | ------ | ------ | ---- | ---- |
        | Create | Project | Mutation | `VulnerabilityCreate` |
        | Read | Project | Type | `Vulnerability` |

        ### CI/CD resources

        #### Pipeline

        Grants the ability to read pipelines

        | Action | Access | Kind | Name |
        | ------ | ------ | ---- | ---- |
        | Read | Project | Field | `ProjectType.pipelines` |
      MARKDOWN
    end

    it 'returns the expected markdown' do
      expect(task.allowed_fields).to eq(expected_markdown)
    end

    context 'when the same element appears more than once' do
      let(:vulnerability_type) do
        type = mock_type('Vulnerability')
        directives = [directive(:read_vulnerability), directive(:read_vulnerability)]
        allow(type).to receive(:directives).and_return(directives)
        type
      end

      it 'de-duplicates identical rows' do
        expect(task.allowed_fields.scan('| Read | Project | Type | `Vulnerability` |').length).to eq(1)
      end
    end

    context 'when resource names differ only in letter case' do
      let(:cd_application_assignable) do
        instance_double(::Authz::PermissionGroups::Assignable,
          category_name: 'CI/CD',
          resource_name: 'CD Application',
          resource_description: 'Grants the ability to read continuous deployment applications',
          action: 'read'
        )
      end

      let(:catalog_resource_assignable) do
        instance_double(::Authz::PermissionGroups::Assignable,
          category_name: 'CI/CD',
          resource_name: 'Catalog Resource',
          resource_description: 'Grants the ability to read CI catalog resources',
          action: 'read'
        )
      end

      before do
        allow(GitlabSchema).to receive(:types).and_return(
          'CdApplication' => mock_type('CdApplication', directive: directive(:read_cd_application)),
          'CatalogResource' => mock_type('CatalogResource', directive: directive(:read_catalog_resource)),
          'Mutation' => mutation_type_with_fields({})
        )
        allow(::Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_cd_application).and_return([cd_application_assignable])
        allow(::Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_catalog_resource).and_return([catalog_resource_assignable])
      end

      it 'sorts resources case-insensitively' do
        output = task.allowed_fields

        expect(output.index('#### Catalog Resource')).to be < output.index('#### CD Application')
      end
    end

    context 'when two resource names downcase identically' do
      let(:glql_upper_assignable) do
        instance_double(::Authz::PermissionGroups::Assignable,
          category_name: 'Monitoring',
          resource_name: 'GLQL',
          resource_description: 'Grants the ability to read GLQL queries',
          action: 'read'
        )
      end

      let(:glql_title_assignable) do
        instance_double(::Authz::PermissionGroups::Assignable,
          category_name: 'Monitoring',
          resource_name: 'Glql',
          resource_description: 'Grants the ability to read Glql queries',
          action: 'read'
        )
      end

      let(:glql_upper_type) { mock_type('GlqlUpper', directive: directive(:read_glql_upper)) }
      let(:glql_title_type) { mock_type('GlqlTitle', directive: directive(:read_glql_title)) }

      before do
        allow(::Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_glql_upper).and_return([glql_upper_assignable])
        allow(::Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_glql_title).and_return([glql_title_assignable])
      end

      it 'orders them deterministically regardless of input order' do
        allow(GitlabSchema).to receive(:types).and_return(
          'GlqlUpper' => glql_upper_type,
          'GlqlTitle' => glql_title_type,
          'Mutation' => mutation_type_with_fields({})
        )
        upper_first = described_class.new.allowed_fields

        allow(GitlabSchema).to receive(:types).and_return(
          'GlqlTitle' => glql_title_type,
          'GlqlUpper' => glql_upper_type,
          'Mutation' => mutation_type_with_fields({})
        )
        title_first = described_class.new.allowed_fields

        expect(upper_first).to eq(title_first)
        expect(upper_first.index('#### GLQL')).to be < upper_first.index('#### Glql')
      end
    end

    context 'when a permission has no assignable group' do
      before do
        allow(::Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_vulnerability).and_return([])
      end

      it 'omits the element' do
        expect(task.allowed_fields).not_to include('`Vulnerability`')
      end
    end

    context 'when an element requires more than its primary permission' do
      let(:merge_request_assignable) do
        instance_double(::Authz::PermissionGroups::Assignable,
          category_name: 'CI/CD',
          resource_name: 'Merge Request',
          resource_description: 'Grants the ability to read merge requests',
          action: 'read'
        )
      end

      let(:deployment_assignable) do
        instance_double(::Authz::PermissionGroups::Assignable,
          category_name: 'CI/CD',
          resource_name: 'Deployment',
          resource_description: 'Grants the ability to read deployments',
          action: 'read'
        )
      end

      let(:deployment_type) do
        mock_type('Deployment', directive: directive(:read_deployment, :read_merge_request))
      end

      before do
        allow(GitlabSchema).to receive(:types).and_return(
          'Deployment' => deployment_type,
          'Mutation' => mutation_type_with_fields({})
        )
        allow(::Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_deployment).and_return([deployment_assignable])
        allow(::Authz::PermissionGroups::Assignable).to receive(:available_for_permission)
          .with(:read_merge_request).and_return([merge_request_assignable])
      end

      it 'marks the action with a footnote listing the additional permission' do
        expect(task.allowed_fields).to eq(<<~MARKDOWN.chomp)
          ### CI/CD resources

          #### Deployment

          Grants the ability to read deployments

          | Action | Access | Kind | Name |
          | ------ | ------ | ---- | ---- |
          | Read <sup>1</sup> | Project | Type | `Deployment` |

          <sup>1</sup> Also requires the `Read Merge Request` permission.
        MARKDOWN
      end
    end
  end

  describe '#compile_docs' do
    subject(:compile_docs) { task.compile_docs }

    before do
      allow(task).to receive(:doc_path).and_return(doc_path)
      FileUtils.mkdir_p(path)
    end

    it 'outputs a success message' do
      expect { compile_docs }.to output("GraphQL field documentation compiled\n").to_stdout
    end

    it 'creates the doc', :aggregate_failures do
      FileUtils.rm_f(doc_path)
      expect { File.read(doc_path) }.to raise_error(Errno::ENOENT)

      compile_docs

      expect(File.read(doc_path)).to match(/This documentation is auto-generated by a Rake task/)
    end
  end

  describe '#check_docs' do
    subject(:check_docs) { task.check_docs }

    before do
      allow(task).to receive(:doc_path).and_return(doc_path)
      FileUtils.mkdir_p(path)
      task.compile_docs
    end

    context 'when the docs are up to date' do
      it 'outputs a success message' do
        expect { check_docs }.to output("GraphQL field documentation is up-to-date\n").to_stdout
      end
    end

    context 'when the doc is updated manually' do
      before do
        File.write(doc_path, 'Manually adding this line at the end of the doc', mode: 'a+')
      end

      let(:error_message) do
        <<~OUTPUT
          ##########
          #
          # GraphQL field documentation is outdated! Please update it by running `bundle exec rake gitlab:permissions:graphql:compile_docs`.
          #
          ##########
        OUTPUT
      end

      it 'raises an error' do
        expect { check_docs }.to raise_error(SystemExit).and output(error_message).to_stdout
      end
    end
  end

  def directive(*permissions, boundary_type: :project)
    Class.new(Directives::Authz::GranularScope).allocate.tap do |d|
      allow(d).to receive(:arguments).and_return(
        permissions: permissions.map { |p| p.to_s.upcase },
        boundary_type: boundary_type.to_s.upcase
      )
    end
  end

  def mock_type(name, directive: nil, fields: nil)
    directives = directive ? [directive] : []

    type = Object.new
    type.define_singleton_method(:name) { name }
    type.define_singleton_method(:kind) { type }
    type.define_singleton_method(:object?) { true }
    type.define_singleton_method(:directives) { directives }

    if fields
      type.define_singleton_method(:respond_to?) { |method, *| %i[kind directives fields].include?(method) }
      type.define_singleton_method(:fields) { fields }
    else
      type.define_singleton_method(:respond_to?) { |method, *| %i[kind directives].include?(method) }
    end

    type
  end

  def mock_field(directive: nil)
    directives = directive ? [directive] : []

    field = Object.new
    field.define_singleton_method(:respond_to?) { |method, *| %i[directives].include?(method) }
    field.define_singleton_method(:directives) { directives }
    field
  end

  def mock_resolver(graphql_name:)
    Class.new(Mutations::BaseMutation) do
      self.graphql_name = graphql_name
    end
  end

  def mock_mutation_field(resolver:, directive: nil)
    directives = directive ? [directive] : []

    field = Object.new
    field.define_singleton_method(:respond_to?) { |method, *| %i[resolver_class directives].include?(method) }
    field.define_singleton_method(:resolver_class) { resolver }
    field.define_singleton_method(:directives) { directives }
    field
  end

  def mutation_type_with_fields(fields)
    type = Object.new
    type.define_singleton_method(:respond_to?) { |method, *| %i[kind fields directives].include?(method) }
    type.define_singleton_method(:kind) { type }
    type.define_singleton_method(:object?) { true }
    type.define_singleton_method(:directives) { [] }
    type.define_singleton_method(:fields) { fields }
    type
  end
end
