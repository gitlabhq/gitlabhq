# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Experimental::O11yServiceSettings", feature_category: :observability do
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

  describe "GET experimental_o11y_service_setting_path" do
    subject(:make_request) { get new_experimental_o11y_service_setting_path }

    it_behaves_like 'requires authentication'
    it_behaves_like 'requires experimental access'

    context 'when experimental_group_o11y_settings_access feature flag is enabled' do
      before do
        stub_feature_flags(experimental_group_o11y_settings_access: user)
      end

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
      before do
        stub_feature_flags(experimental_group_o11y_settings_access: user)
      end

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
                  s_('Observability|Observability settings for group ID %{group_id} created successfully.'),
                  group_id: group.id
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

          it 'renders new template with unprocessable_entity status' do
            make_request

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(response).to render_template(:new)
          end
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

  def stub_o11y_setting_save(result)
    allow_next_instance_of(Observability::GroupO11ySetting) do |instance|
      allow(instance).to receive(:save).and_return(result)
    end
  end
end
