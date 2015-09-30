require "spec_helper"

describe API::API, api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
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

      it "should get #{service} settings" do
        get api("/projects/#{project.id}/services/#{dashed_service}", user)

        expect(response.status).to eq(200)
      end
    end
  end
end
