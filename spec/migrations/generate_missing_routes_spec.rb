require 'spec_helper'
require Rails.root.join('db', 'migrate', '20180702134423_generate_missing_routes.rb')

describe GenerateMissingRoutes, :migration do
  describe '#up' do
    let(:namespaces) { table(:namespaces) }
    let(:projects) { table(:projects) }
    let(:routes) { table(:routes) }

    it 'creates routes for projects without a route' do
      namespace = namespaces.create!(name: 'GitLab', path: 'gitlab', type: 'Group')

      routes.create!(
        path: 'gitlab',
        source_type: 'Namespace',
        source_id: namespace.id
      )

      project = projects.create!(
        name: 'GitLab CE',
        path: 'gitlab-ce',
        namespace_id: namespace.id
      )

      described_class.new.up

      route = routes.where(source_type: 'Project').take

      expect(route.source_id).to eq(project.id)
      expect(route.path).to eq("gitlab/gitlab-ce-#{project.id}")
    end

    it 'creates routes for namespaces without a route' do
      namespace = namespaces.create!(name: 'GitLab', path: 'gitlab')

      described_class.new.up

      route = routes.where(source_type: 'Namespace').take

      expect(route.source_id).to eq(namespace.id)
      expect(route.path).to eq("gitlab-#{namespace.id}")
    end

    it 'does not create routes for namespaces that already have a route' do
      namespace = namespaces.create!(name: 'GitLab', path: 'gitlab')

      routes.create!(
        path: 'gitlab',
        source_type: 'Namespace',
        source_id: namespace.id
      )

      described_class.new.up

      expect(routes.count).to eq(1)
    end

    it 'does not create routes for projects that already have a route' do
      namespace = namespaces.create!(name: 'GitLab', path: 'gitlab')

      routes.create!(
        path: 'gitlab',
        source_type: 'Namespace',
        source_id: namespace.id
      )

      project = projects.create!(
        name: 'GitLab CE',
        path: 'gitlab-ce',
        namespace_id: namespace.id
      )

      routes.create!(
        path: 'gitlab/gitlab-ce',
        source_type: 'Project',
        source_id: project.id
      )

      described_class.new.up

      expect(routes.count).to eq(2)
    end
  end
end
