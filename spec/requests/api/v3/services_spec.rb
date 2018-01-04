require "spec_helper"

describe API::V3::Services do
  let(:user) { create(:user) }
  let(:project) { create(:project, creator_id: user.id, namespace: user.namespace) }

  available_services = Service.available_services_names
  available_services.delete('prometheus')
  available_services.each do |service|
    describe "DELETE /projects/:id/services/#{service.dasherize}" do
      include_context service

      before do
        initialize_service(service)
      end

      it "deletes #{service}" do
        delete v3_api("/projects/#{project.id}/services/#{dashed_service}", user)

        expect(response).to have_gitlab_http_status(200)
        project.send(service_method).reload
        expect(project.send(service_method).activated?).to be_falsey
      end
    end
  end
end
