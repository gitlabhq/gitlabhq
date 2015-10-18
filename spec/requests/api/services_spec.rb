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

      it "should update #{service} settings" do
        put api("/projects/#{project.id}/services/#{dashed_service}", user), service_attrs

        expect(response.status).to eq(200)
      end

      it "should return if required fields missing" do
        attrs = service_attrs

        required_attributes = service_attrs_list.select do |attr|
          service_klass.validators_on(attr).any? do |v|
            v.class == ActiveRecord::Validations::PresenceValidator
          end
        end

        if required_attributes.empty?
          expected_code = 200
        else
          attrs.delete(required_attributes.shuffle.first)
          expected_code = 400
        end
        
        put api("/projects/#{project.id}/services/#{dashed_service}", user), attrs

        expect(response.status).to eq(expected_code)
      end
    end

    describe "DELETE /projects/:id/services/#{service.dasherize}" do
      include_context service

      it "should delete #{service}" do
        delete api("/projects/#{project.id}/services/#{dashed_service}", user)

        expect(response.status).to eq(200)
        expect(project.send(service_method).activated?).to be_falsey
      end
    end

    describe "GET /projects/:id/services/#{service.dasherize}" do
      include_context service

      # inject some properties into the service
      before do
        project.build_missing_services
        service_object = project.send(service_method)
        service_object.properties = service_attrs
        service_object.save
      end

      it 'should return authentication error when unauthenticated' do
        get api("/projects/#{project.id}/services/#{dashed_service}")
        expect(response.status).to eq(401)
      end
      
      it "should return all properties of service #{service} when authenticated as admin" do
        get api("/projects/#{project.id}/services/#{dashed_service}", admin)
        
        expect(response.status).to eq(200)
        expect(json_response['properties'].keys.map(&:to_sym)).to match_array(service_attrs_list.map)
      end

      it "should return properties of service #{service} other than passwords when authenticated as project owner" do
        get api("/projects/#{project.id}/services/#{dashed_service}", user)

        expect(response.status).to eq(200)
        expect(json_response['properties'].keys.map(&:to_sym)).to match_array(service_attrs_list_without_passwords)
      end

      it "should return error when authenticated but not a project owner" do
        project.team << [user2, :developer]
        get api("/projects/#{project.id}/services/#{dashed_service}", user2)
        
        expect(response.status).to eq(403)
      end

    end
  end
end
