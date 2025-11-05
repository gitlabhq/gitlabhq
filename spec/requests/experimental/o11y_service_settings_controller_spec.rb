# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Experimental::O11yServiceSettingsController, feature_category: :observability do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    stub_const('TEST_SERVICE_NAME', 'test-service')
    stub_const('TEST_EMAIL', 'user@example.com')
    stub_const('TEST_PASSWORD', 'secure_password')
    stub_const('TEST_ENCRYPTION_KEY', 'encryption_key')
    stub_const('INVALID_EMAIL', 'invalid_email')
    sign_in(user)
  end

  shared_examples 'requires authentication' do
    context 'when user is not authenticated' do
      before do
        sign_out(user)
      end

      it 'redirects to sign in' do
        make_request
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  shared_examples 'requires experimental access' do
    context 'when experimental_group_o11y_settings_access feature flag is disabled' do
      before do
        stub_feature_flags(experimental_group_o11y_settings_access: false)
      end

      it 'returns 404' do
        make_request
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_examples 'successful response' do |template|
    it 'returns success and renders template' do
      make_request

      aggregate_failures do
        expect(response).to have_gitlab_http_status(:success)
        expect(response).to render_template(template)
      end
    end
  end

  shared_examples 'unprocessable entity response' do |template|
    it 'renders template with unprocessable_entity status' do
      make_request

      aggregate_failures do
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(response).to render_template(template)
      end
    end
  end

  shared_context 'with feature flag enabled context' do
    before do
      stub_feature_flags(experimental_group_o11y_settings_access: user)
    end
  end

  describe "GET experimental_o11y_service_settings_path" do
    subject(:make_request) { get experimental_o11y_service_settings_path }

    it_behaves_like 'requires authentication'
    it_behaves_like 'requires experimental access'

    context 'when experimental_group_o11y_settings_access feature flag is enabled' do
      include_examples 'with feature flag enabled context'

      context 'when no o11y service settings exist' do
        it 'returns success and renders index template with empty collection' do
          make_request

          aggregate_failures do
            expect(assigns(:o11y_service_settings)).to be_empty
            expect(response).to have_gitlab_http_status(:success)
            expect(response).to render_template(:index)
          end
        end
      end

      context 'when o11y service settings exist' do
        let_it_be(:group1) { create(:group) }
        let_it_be(:group2) { create(:group) }
        let_it_be(:o11y_setting1) { create(:observability_group_o11y_setting, group: group1) }
        let_it_be(:o11y_setting2) { create(:observability_group_o11y_setting, group: group2) }

        it 'returns success and renders index template with paginated collection' do
          make_request

          aggregate_failures do
            expect(assigns(:o11y_service_settings)).to include(o11y_setting1, o11y_setting2)
            expect(response).to have_gitlab_http_status(:success)
            expect(response).to render_template(:index)
          end
        end

        context 'with pagination' do
          before do
            25.times do
              group = create(:group)
              create(:observability_group_o11y_setting, group: group)
            end
          end

          it 'handles pagination correctly', :aggregate_failures do
            get experimental_o11y_service_settings_path, params: { page: 1 }
            expect(assigns(:o11y_service_settings).count).to eq(20)
            expect(response).to have_gitlab_http_status(:success)
            expect(response).to render_template(:index)

            get experimental_o11y_service_settings_path, params: { page: 2 }
            expect(assigns(:o11y_service_settings).count).to eq(7)
            expect(response).to have_gitlab_http_status(:success)
            expect(response).to render_template(:index)
          end
        end

        context 'with group_id search parameter' do
          it 'filters results by group_id' do
            get experimental_o11y_service_settings_path, params: { group_id: group1.id }

            aggregate_failures do
              expect(assigns(:o11y_service_settings)).to include(o11y_setting1)
              expect(assigns(:o11y_service_settings)).not_to include(o11y_setting2)
              expect(response).to have_gitlab_http_status(:success)
              expect(response).to render_template(:index)
            end
          end

          it 'returns empty results for non-existent group_id' do
            get experimental_o11y_service_settings_path, params: { group_id: 999999 }

            aggregate_failures do
              expect(assigns(:o11y_service_settings)).to be_empty
              expect(response).to have_gitlab_http_status(:success)
              expect(response).to render_template(:index)
            end
          end

          it 'ignores empty group_id parameter' do
            get experimental_o11y_service_settings_path, params: { group_id: '' }

            aggregate_failures do
              expect(assigns(:o11y_service_settings)).to include(o11y_setting1, o11y_setting2)
              expect(response).to have_gitlab_http_status(:success)
              expect(response).to render_template(:index)
            end
          end
        end
      end
    end
  end

  describe "GET experimental_o11y_service_setting_path" do
    subject(:make_request) { get new_experimental_o11y_service_setting_path }

    it_behaves_like 'requires authentication'
    it_behaves_like 'requires experimental access'

    context 'when experimental_group_o11y_settings_access feature flag is enabled' do
      include_examples 'with feature flag enabled context'

      it 'returns success and renders new template' do
        make_request

        aggregate_failures do
          expect(assigns(:o11y_service_settings)).to be_a_new(Observability::GroupO11ySetting)
          expect(response).to have_gitlab_http_status(:success)
          expect(response).to render_template(:new)
        end
      end
    end
  end

  describe "POST experimental_o11y_service_settings_path" do
    subject(:make_request) { post experimental_o11y_service_settings_path, params: params }

    let(:params) { valid_params }

    let(:valid_params) do
      { observability_group_o11y_setting: build_settings_params }
    end

    let(:invalid_params) do
      {
        observability_group_o11y_setting: build_settings_params(
          o11y_service_name: '',
          o11y_service_user_email: INVALID_EMAIL,
          o11y_service_password: '',
          o11y_service_post_message_encryption_key: ''
        )
      }
    end

    it_behaves_like 'requires authentication'
    it_behaves_like 'requires experimental access'

    context 'when experimental_group_o11y_settings_access feature flag is enabled' do
      include_examples 'with feature flag enabled context'

      context 'with mocked service' do
        let(:mock_service) { instance_double(Observability::GroupO11ySettingsUpdateService) }

        before do
          allow(Observability::GroupO11ySettingsUpdateService).to receive(:new).and_return(mock_service)
        end

        context 'with valid parameters' do
          let(:success_response) do
            ServiceResponse.success(payload: { settings: instance_double(Observability::GroupO11ySetting) })
          end

          before do
            success_response = ServiceResponse.success(payload: {
              settings: instance_double(Observability::GroupO11ySetting)
            })
            allow(mock_service).to receive(:execute).and_return(success_response)
            stub_o11y_setting_save(true)
          end

          it 'creates the o11y service settings successfully' do
            make_request

            aggregate_failures do
              expect(mock_service).to have_received(:execute)
              expect(response).to redirect_to(new_experimental_o11y_service_setting_url)
              expect(flash[:success]).to eq(
                format(
                  s_('Observability|Observability settings for group %{group_name} created successfully.'),
                  group_name: group.name
                )
              )
            end
          end

          it 'calls the update service with correct parameters' do
            expect(mock_service).to receive(:execute).with(
              an_instance_of(Observability::GroupO11ySetting),
              hash_including(expected_params_hash)
            )

            make_request
          end
        end

        context 'with invalid parameters' do
          let(:params) { invalid_params }
          let(:error_response) { ServiceResponse.error(message: 'Email is invalid, Password is required') }

          before do
            allow(mock_service).to receive(:execute).and_return(error_response)
          end

          it 'renders new template with unprocessable_entity status' do
            make_request

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(response).to render_template(:new)
          end

          it 'calls the service with invalid parameters' do
            expect(mock_service).to receive(:execute).with(
              an_instance_of(Observability::GroupO11ySetting),
              hash_including(
                group_id: group.id.to_s,
                o11y_service_name: '',
                o11y_service_user_email: INVALID_EMAIL,
                o11y_service_password: '',
                o11y_service_post_message_encryption_key: ''
              )
            )

            make_request
          end
        end

        context 'when service execution fails' do
          let(:error_response) { ServiceResponse.error(message: 'Service error') }

          before do
            allow(mock_service).to receive(:execute).and_return(error_response)
            stub_o11y_setting_save(false)
          end

          it_behaves_like 'unprocessable entity response', :new
        end

        context 'when group is not found' do
          let(:params) do
            {
              observability_group_o11y_setting: build_settings_params(
                group_id: 999999
              )
            }
          end

          it 'renders new template with unprocessable_entity status and sets flash alert' do
            make_request

            aggregate_failures do
              expect(response).to have_gitlab_http_status(:unprocessable_entity)
              expect(response).to render_template(:new)
              expect(flash[:alert]).to eq('Group not found')
              expect(assigns(:o11y_service_settings)).to be_a(Observability::GroupO11ySetting)
            end
          end

          it 'does not call the update service' do
            expect(Observability::GroupO11ySettingsUpdateService).not_to receive(:new)

            make_request
          end
        end

        context 'when o11y service settings already exist' do
          let_it_be(:existing_settings) { create(:observability_group_o11y_setting, group: group) }

          it 'renders new template with unprocessable_entity status and sets flash alert' do
            make_request

            aggregate_failures do
              expect(response).to have_gitlab_http_status(:unprocessable_entity)
              expect(response).to render_template(:new)
              expect(flash[:alert]).to eq('O11y service settings already exist')
              expect(assigns(:o11y_service_settings)).to be_a(Observability::GroupO11ySetting)
            end
          end

          it 'does not call the update service' do
            expect(Observability::GroupO11ySettingsUpdateService).not_to receive(:new)

            make_request
          end
        end
      end
    end
  end

  describe 'GET #edit' do
    let_it_be(:o11y_setting) { create(:observability_group_o11y_setting, group: group) }
    let(:make_request) { get edit_experimental_o11y_service_setting_path(o11y_setting) }

    include_examples 'requires authentication'
    include_examples 'requires experimental access'

    context 'when user is authenticated and has experimental access' do
      before do
        stub_feature_flags(experimental_group_o11y_settings_access: user)
      end

      include_examples 'successful response', :edit

      it 'assigns the correct o11y service setting' do
        make_request
        expect(assigns(:o11y_service_settings)).to eq(o11y_setting)
      end
    end

    context 'when o11y service setting is not found' do
      before do
        stub_feature_flags(experimental_group_o11y_settings_access: user)
      end

      let(:make_request) { get edit_experimental_o11y_service_setting_path(999999) }

      it 'returns 404' do
        make_request
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'PATCH #update' do
    let_it_be(:o11y_setting) { create(:observability_group_o11y_setting, group: group) }
    let(:make_request) do
      patch experimental_o11y_service_setting_path(o11y_setting),
        params: { observability_group_o11y_setting: build_settings_params }
    end

    include_examples 'requires authentication'
    include_examples 'requires experimental access'

    context 'when user is authenticated and has experimental access' do
      before do
        stub_feature_flags(experimental_group_o11y_settings_access: user)
      end

      context 'when update is successful' do
        before do
          allow_next_instance_of(Observability::GroupO11ySettingsUpdateService) do |service|
            allow(service).to receive(:execute).and_return(ServiceResponse.success)
          end
        end

        it 'redirects to index with success message' do
          make_request

          aggregate_failures do
            expect(response).to redirect_to(experimental_o11y_service_settings_path)
            expect(flash[:success]).to include('updated successfully')
          end
        end

        it 'calls the update service with correct parameters' do
          expect_next_instance_of(Observability::GroupO11ySettingsUpdateService) do |service|
            expect(service).to receive(:execute).with(o11y_setting,
              expected_update_params_hash).and_return(ServiceResponse.success)
          end

          make_request
        end
      end

      context 'when update fails' do
        before do
          allow_next_instance_of(Observability::GroupO11ySettingsUpdateService) do |service|
            allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'Update failed'))
          end
        end

        it 'renders edit template with error message' do
          make_request

          aggregate_failures do
            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(response).to render_template(:edit)
            expect(flash[:alert]).to eq('Failed to update O11y service settings')
          end
        end
      end
    end

    context 'when o11y service setting is not found' do
      before do
        stub_feature_flags(experimental_group_o11y_settings_access: user)
      end

      let(:make_request) do
        patch experimental_o11y_service_setting_path(999999),
          params: { observability_group_o11y_setting: build_settings_params }
      end

      it 'returns 404' do
        make_request
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'DELETE #destroy' do
    let_it_be(:o11y_setting) { create(:observability_group_o11y_setting, group: group) }
    let(:make_request) do
      delete experimental_o11y_service_setting_path(o11y_setting)
    end

    include_examples 'requires authentication'
    include_examples 'requires experimental access'

    context 'when user is authenticated and has experimental access' do
      before do
        stub_feature_flags(experimental_group_o11y_settings_access: user)
      end

      context 'when destroy is successful' do
        it 'redirects to index with success message' do
          make_request

          aggregate_failures do
            expect(response).to redirect_to(experimental_o11y_service_settings_path)
            expect(flash[:success]).to include('deleted successfully')
            expect(flash[:success]).to include(o11y_setting.group.name.to_s)
          end
        end

        it 'deletes the o11y service setting' do
          expect { make_request }.to change { Observability::GroupO11ySetting.count }.by(-1)
        end
      end

      context 'when destroy fails' do
        let(:mocked_setting) { instance_double(Observability::GroupO11ySetting, group: group, destroy: false) }

        before do
          allow(Observability::GroupO11ySetting).to receive(:find_by_id)
            .with(o11y_setting.id.to_s).and_return(mocked_setting)
        end

        it 'redirects to index with error message' do
          make_request

          aggregate_failures do
            expect(response).to redirect_to(experimental_o11y_service_settings_path)
            expect(flash[:alert]).to eq('Failed to delete O11y service settings')
          end
        end

        it 'does not delete the o11y service setting' do
          expect { make_request }.not_to change { Observability::GroupO11ySetting.count }
        end
      end
    end

    context 'when o11y service setting is not found' do
      before do
        stub_feature_flags(experimental_group_o11y_settings_access: user)
      end

      let(:make_request) do
        delete experimental_o11y_service_setting_path(999999)
      end

      it 'returns 404' do
        make_request
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  private

  def build_settings_params(**overrides)
    {
      group_id: group.id,
      o11y_service_name: TEST_SERVICE_NAME,
      o11y_service_user_email: TEST_EMAIL,
      o11y_service_password: TEST_PASSWORD,
      o11y_service_post_message_encryption_key: TEST_ENCRYPTION_KEY
    }.merge(overrides)
  end

  def expected_params_hash
    {
      group_id: group.id.to_s,
      o11y_service_name: TEST_SERVICE_NAME,
      o11y_service_user_email: TEST_EMAIL,
      o11y_service_password: TEST_PASSWORD,
      o11y_service_post_message_encryption_key: TEST_ENCRYPTION_KEY
    }
  end

  def expected_update_params_hash
    {
      o11y_service_name: TEST_SERVICE_NAME,
      o11y_service_user_email: TEST_EMAIL,
      o11y_service_password: TEST_PASSWORD,
      o11y_service_post_message_encryption_key: TEST_ENCRYPTION_KEY
    }
  end

  def stub_o11y_setting_save(result)
    allow_next_instance_of(Observability::GroupO11ySetting) do |instance|
      allow(instance).to receive(:save).and_return(result)
    end
  end
end
