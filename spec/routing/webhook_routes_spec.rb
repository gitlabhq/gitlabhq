require "spec_helper"

describe "routes to the proper webhooks controller", type: :routing do
  context 'with a project context' do
    let(:project) { create(:project) }
    let(:project_hook) { create(:project_hook) }

    it "routes the test action" do
      expect(
        get: polymorphic_path([project.namespace.becomes(Namespace), project, project_hook], action: :test)
      ).to route_to(controller: 'projects/hooks',
                    action: 'test',
                    namespace_id: project.namespace.name,
                    project_id: project.path,
                    id: project_hook.id.to_s)
    end

    it "routes a single record" do
      expect(
        delete: polymorphic_path([project.namespace.becomes(Namespace), project, project_hook])
      ).to route_to(controller: 'projects/hooks',
                    action: 'destroy',
                    namespace_id: project.namespace.name,
                    project_id: project.path,
                    id: project_hook.id.to_s)
    end
  end

  context 'with a group context' do
    let(:group) { create(:group, name: 'gitlab') }
    let(:group_hook) { create(:group_hook) }

    it "routes the test action" do
      expect(
        get: polymorphic_path([group, group_hook], action: :test)
      ).to route_to(controller: 'groups/hooks',
                    action: 'test',
                    group_id: group.name,
                    id: group_hook.id.to_s)
    end

    it "routes a single record" do
      expect(
        delete: polymorphic_path([group, group_hook])
      ).to route_to(controller: 'groups/hooks',
                    action: 'destroy',
                    group_id: group.name,
                    id: group_hook.id.to_s)
    end
  end
end
