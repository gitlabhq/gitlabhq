require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170518231126_fix_wrongly_renamed_routes.rb')

describe FixWronglyRenamedRoutes, :migration do
  let(:subject) { described_class.new }
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:routes_table) { table(:routes) }
  let(:broken_namespace) do
    namespaces_table.create!(name: 'apiis', path: 'apiis').tap do |namespace|
      routes_table.create!(source_type: 'Namespace', source_id: namespace.id, name: 'api0is', path: 'api0is')
    end
  end
  let(:broken_namespace_route) { routes_table.where(source_type: 'Namespace', source_id: broken_namespace.id).first }

  describe '#wrongly_renamed' do
    it "includes routes that have names that don't match their namespace" do
      broken_namespace
      other_namespace = namespaces_table.create!(name: 'api0', path: 'api0')
      routes_table.create!(source_type: 'Namespace', source_id: other_namespace.id, name: 'api0', path: 'api0')

      expect(subject.wrongly_renamed.map(&:id))
        .to contain_exactly(broken_namespace_route.id)
    end
  end

  describe "#paths_and_corrections" do
    it 'finds the wrong path and gets the correction from the namespace' do
      broken_namespace
      namespaces_table.create!(name: 'uploads-test', path: 'uploads-test').tap do |namespace|
        routes_table.create!(source_type: 'Namespace', source_id: namespace.id, name: 'uploads-test', path: 'uploads0-test')
      end

      expected_result = [
        { 'namespace_path' => 'apiis', 'path' => 'api0is' },
        { 'namespace_path' => 'uploads-test', 'path' => 'uploads0-test' }
      ]

      expect(subject.paths_and_corrections).to include(*expected_result)
    end
  end

  describe '#routes_in_namespace_query' do
    it 'includes only the required routes' do
      namespace = namespaces_table.create!(name: 'hello', path: 'hello')
      namespace_route = routes_table.create!(source_type: 'Namespace', source_id: namespace.id, name: 'hello', path: 'hello')
      project = projects_table.new(name: 'my-project', path: 'my-project', namespace_id: namespace.id).tap do |project|
        project.save!(validate: false)
      end
      routes_table.create!(source_type: 'Project', source_id: project.id, name: 'my-project', path: 'hello/my-project')
      _other_namespace = namespaces_table.create!(name: 'hello0', path: 'hello0')

      result = routes_table.where(subject.routes_in_namespace_query('hello'))
      project_route = routes_table.where(source_type: 'Project', source_id: project.id).first

      expect(result).to contain_exactly(namespace_route, project_route)
    end
  end

  describe '#up' do
    it 'renames incorrectly named routes' do
      broken_project =
        projects_table.new(name: 'broken-project', path: 'broken-project', namespace_id: broken_namespace.id).tap do |project|
          project.save!(validate: false)
          routes_table.create!(source_type: 'Project', source_id: project.id, name: 'broken-project', path: 'api0is/broken-project')
        end

      subject.up

      broken_project_route = routes_table.where(source_type: 'Project', source_id: broken_project.id).first

      expect(broken_project_route.path).to eq('apiis/broken-project')
      expect(broken_namespace_route.reload.path).to eq('apiis')
    end

    it "doesn't touch namespaces that look like something that should be renamed" do
      namespaces_table.create!(name: 'apiis', path: 'apiis')
      namespace = namespaces_table.create!(name: 'hello', path: 'api0')
      namespace_route = routes_table.create!(source_type: 'Namespace', source_id: namespace.id, name: 'hello', path: 'api0')

      subject.up

      expect(namespace_route.reload.path).to eq('api0')
    end
  end
end
