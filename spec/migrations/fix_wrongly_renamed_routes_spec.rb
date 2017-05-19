require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170518231126_fix_wrongly_renamed_routes.rb')

describe FixWronglyRenamedRoutes, truncate: true do
  let(:subject) { described_class.new }
  let(:broken_namespace) do
    namespace = create(:group, name: 'apiis')
    namespace.route.update_attribute(:path, 'api0is')
    namespace
  end

  describe '#wrongly_renamed' do
    it "includes routes that have names that don't match their namespace" do
      broken_namespace
      _other_namespace = create(:group, name: 'api0')

      expect(subject.wrongly_renamed.map(&:id))
        .to contain_exactly(broken_namespace.route.id)
    end
  end

  describe "#paths_and_corrections" do
    it 'finds the wrong path and gets the correction from the namespace' do
      broken_namespace
      namespace = create(:group, name: 'uploads-test')
      namespace.route.update_attribute(:path, 'uploads0-test')

      expected_result = [
        { 'namespace_path' => 'apiis', 'path' => 'api0is' },
        { 'namespace_path' => 'uploads-test', 'path' => 'uploads0-test' }
      ]

      expect(subject.paths_and_corrections).to include(*expected_result)
    end
  end

  describe '#routes_in_namespace_query' do
    it 'includes only the required routes' do
      namespace = create(:group, path: 'hello')
      project = create(:empty_project, namespace: namespace)
      _other_namespace = create(:group, path: 'hello0')

      result = Route.where(subject.routes_in_namespace_query('hello'))

      expect(result).to contain_exactly(namespace.route, project.route)
    end
  end

  describe '#up' do
    let(:broken_project) do
      project = create(:empty_project, namespace: broken_namespace, path: 'broken-project')
      project.route.update_attribute(:path, 'api0is/broken-project')
      project
    end

    it 'renames incorrectly named routes' do
      broken_project

      subject.up

      expect(broken_project.route.reload.path).to eq('apiis/broken-project')
      expect(broken_namespace.route.reload.path).to eq('apiis')
    end

    it "doesn't touch namespaces that look like something that should be renamed" do
      namespace = create(:group, path: 'api0')

      subject.up

      expect(namespace.route.reload.path).to eq('api0')
    end
  end
end
