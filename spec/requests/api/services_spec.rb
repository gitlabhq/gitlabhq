require "spec_helper"

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let(:user2) { create(:user) }
  let(:project) {create(:project, creator_id: user.id, namespace: user.namespace) }

  Service.available_services_names.each do |service|
    describe "PUT /projects/:id/services/#{service.dasherize}" do
      include_context service

      it "updates #{service} settings" do
        put api("/projects/#{project.id}/services/#{dashed_service}", user), service_attrs

        expect(response).to have_http_status(200)
      end

      it "returns if required fields missing" do
        attrs = service_attrs

        required_attributes = service_attrs_list.select do |attr|
          service_klass.validators_on(attr).any? do |v|
            v.class == ActiveRecord::Validations::PresenceValidator
          end
        end

        if required_attributes.empty?
          expected_code = 200
        else
          attrs.delete(required_attributes.sample)
          expected_code = 400
        end

        put api("/projects/#{project.id}/services/#{dashed_service}", user), attrs

        expect(response.status).to eq(expected_code)
      end
    end

    describe "DELETE /projects/:id/services/#{service.dasherize}" do
      include_context service

      it "deletes #{service}" do
        delete api("/projects/#{project.id}/services/#{dashed_service}", user)

        expect(response).to have_http_status(200)
        project.send(service_method).reload
        expect(project.send(service_method).activated?).to be_falsey
      end
    end

    describe "GET /projects/:id/services/#{service.dasherize}" do
      include_context service

      # inject some properties into the service
      before do
        service_object = project.find_or_initialize_service(service)
        service_object.properties = service_attrs
        service_object.save
      end

      it 'returns authentication error when unauthenticated' do
        get api("/projects/#{project.id}/services/#{dashed_service}")
        expect(response).to have_http_status(401)
      end

      it "returns all properties of service #{service} when authenticated as admin" do
        get api("/projects/#{project.id}/services/#{dashed_service}", admin)

        expect(response).to have_http_status(200)
        expect(json_response['properties'].keys.map(&:to_sym)).to match_array(service_attrs_list.map)
      end

      it "returns properties of service #{service} other than passwords when authenticated as project owner" do
        get api("/projects/#{project.id}/services/#{dashed_service}", user)

        expect(response).to have_http_status(200)
        expect(json_response['properties'].keys.map(&:to_sym)).to match_array(service_attrs_list_without_passwords)
      end

      it "returns error when authenticated but not a project owner" do
        project.team << [user2, :developer]
        get api("/projects/#{project.id}/services/#{dashed_service}", user2)

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'POST /projects/:id/services/:slug/trigger' do
    let!(:project) { create(:empty_project) }
    let(:service_name) { 'mattermost_command' }

    context 'no service is available' do
      it 'returns a not found message' do
        post api("/projects/#{project.id}/services/mattermost_command/trigger")

        expect(response).to have_http_status(404)
      end
    end

    context 'the service exists' do
      context 'the service is not active' do
        let!(:inactive_service) do
          project.create_mattermost_command_service(
            active: false,
            properties: { token: 'token' }
          )
        end

        it 'when the service is inactive' do
          post api("/projects/#{project.id}/services/mattermost_command/trigger")

          expect(response).to have_http_status(404)
        end
      end

      context 'the service is active' do
        let!(:active_service) do
          project.create_mattermost_command_service(
            active: true,
            properties: { token: 'token' }
          )
        end
        let(:params) { { token: 'token' } }

        it 'retusn status 200' do
          post api("/projects/#{project.id}/services/mattermost_command/trigger"), params

          expect(response).to have_http_status(200)
        end
      end
    end
  end
end
