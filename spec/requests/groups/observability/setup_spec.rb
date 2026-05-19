# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Groups::Observability::Setup", feature_category: :observability do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:user) { create(:user) }

  before_all do
    group.add_developer(user)
  end

  before do
    sign_in(user)
  end

  describe "GET /show" do
    subject(:get_setup_page) { get group_observability_setup_path(group, params) }

    let(:params) { {} }

    include_examples 'observability requires feature flag'

    context 'when feature flag is enabled' do
      before do
        stub_feature_flags(observability_sass_features: group)
      end

      it "returns http success and renders show template" do
        get_setup_page

        aggregate_failures do
          expect(response).to have_gitlab_http_status(:success)
          expect(response).to render_template(:show)
        end
      end

      context 'when group already has observability settings' do
        let_it_be(:o11y_setting) { create(:observability_group_o11y_setting, group: group) }

        it 'returns early without building a new setting' do
          get_setup_page
          expect(response).to have_gitlab_http_status(:success)
          expect(assigns(:group).observability_group_o11y_setting.persisted?).to be_truthy
        end

        describe 'hero section' do
          context 'when no CI/CD export variable is set and no pipelines have run' do
            it 'renders the "Enable CI/CD observability" state' do
              get_setup_page

              aggregate_failures do
                expect(response.body).to include('Enable CI/CD observability')
                expect(response.body).to include('Open CI/CD settings')
              end
            end
          end

          context 'when CI/CD export variable is set but no pipelines have finished' do
            before do
              create(:ci_group_variable, group: group, key: 'GITLAB_OBSERVABILITY_EXPORT', value: 'metrics,logs,traces')
            end

            it 'renders the "Ready to collect telemetry" state' do
              get_setup_page

              aggregate_failures do
                expect(response.body).to include('Ready to collect telemetry')
                expect(response.body).to include('View CI/CD settings')
              end
            end
          end

          context 'when pipelines have finished since setup' do
            before do
              finder = instance_double(
                Observability::PipelinesSinceSetupExist,
                execute: true
              )
              allow(Observability::PipelinesSinceSetupExist)
                .to receive(:new).and_return(finder)
            end

            it 'renders the "pipelines are sending telemetry" state' do
              get_setup_page

              aggregate_failures do
                expect(response.body).to include('Your CI/CD pipelines are sending telemetry')
                expect(response.body).to include('Explore your data')
                expect(response.body).to include(group_observability_path(group, 'dashboard'))
              end
            end
          end
        end

        describe 'page layout and section order' do
          it 'renders the connect your application section before endpoint details' do
            get_setup_page

            body = response.body
            instrument_pos = body.index('Connect your application')
            endpoints_pos  = body.index('Endpoint details')

            aggregate_failures do
              expect(instrument_pos).to be_present,
                'expected "Connect your application" section to be present'
              expect(endpoints_pos).to be_present, 'expected "Endpoint details" section to be present'
              expect(instrument_pos).to be < endpoints_pos,
                '"Connect your application" section should appear before endpoint details'
            end
          end

          it 'renders OpenTelemetry language setup guides' do
            get_setup_page

            aggregate_failures do
              expect(response.body).to include('Ruby')
              expect(response.body).to include('Go')
              expect(response.body).to include('Python')
              expect(response.body).to include('Node.js')
              expect(response.body).to include('Java')
              expect(response.body).to include('.NET')
            end
          end

          it 'renders CI/CD export settings before test endpoints section' do
            get_setup_page

            body = response.body
            cicd_pos    = body.index('CI/CD export settings')
            testing_pos = body.index('Test your endpoints')

            aggregate_failures do
              expect(cicd_pos).to be_present, 'expected CI/CD export settings section to be present'
              expect(testing_pos).to be_present, 'expected "Test your endpoints" section to be present'
              expect(cicd_pos).to be < testing_pos,
                'CI/CD export settings should appear before "Test your endpoints"'
            end
          end

          it 'collapses advanced configuration under "Non-TLS endpoints and advanced configuration"' do
            get_setup_page

            aggregate_failures do
              expect(response.body).to include('Non-TLS endpoints and advanced configuration')
              expect(response.body).to include('Firewall configuration')
            end
          end

          it 'renders endpoint details before the CI/CD export settings' do
            get_setup_page

            body = response.body
            endpoints_pos = body.index('Endpoint details')
            cicd_pos      = body.index('CI/CD export settings')

            expect(endpoints_pos).to be < cicd_pos,
              'Endpoint details should appear before CI/CD export settings'
          end
        end
      end

      context 'when group does not have observability settings' do
        context 'when provisioning parameter is true' do
          let(:params) { { provisioning: 'true' } }

          before do
            allow(Gitlab).to receive(:com?).and_return(true)
          end

          it 'builds observability setting with group id as service name' do
            get_setup_page

            expect(assigns(:group).observability_group_o11y_setting).to be_present
            expect(assigns(:group).observability_group_o11y_setting.o11y_service_name).to eq(group.id)
            expect(assigns(:group).observability_group_o11y_setting.new_record?).to be_truthy
          end
        end

        context 'when provisioning parameter is false or not provided' do
          it 'does not build observability setting' do
            get_setup_page

            expect(assigns(:group).observability_group_o11y_setting).to be_nil
          end
        end

        context 'when on GitLab.com' do
          before do
            allow(Gitlab).to receive(:com?).and_return(true)
          end

          it 'renders the Enable Observability button' do
            get_setup_page

            expect(response.body).to include('Enable Observability')
            expect(response.body).to include(group_observability_access_requests_path(group))
          end
        end

        context 'when not on GitLab.com' do
          before do
            allow(Gitlab).to receive(:com?).and_return(false)
          end

          it 'renders the administrator message instead of the button' do
            get_setup_page

            expect(response.body)
              .to include('please ask your <strong>GitLab administrator</strong> ' \
                'to enable it for this group')
            expect(response.body).not_to include(group_observability_access_requests_path(group))
          end
        end
      end

      include_examples 'observability requires permissions'
    end
  end
end
