# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Operations::UpdateService, feature_category: :groups_and_projects do
  let_it_be_with_refind(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:result) { subject.execute }

  subject { described_class.new(project, user, params) }

  describe '#execute' do
    context 'error tracking' do
      context 'with existing error tracking setting' do
        let(:params) do
          {
            error_tracking_setting_attributes: {
              enabled: false,
              integrated: true,
              api_host: 'http://gitlab.com/',
              token: 'token',
              project: {
                slug: 'project',
                name: 'Project',
                organization_slug: 'org',
                organization_name: 'Org'
              }
            }
          }
        end

        before do
          create(:project_error_tracking_setting, project: project)
        end

        it 'updates the settings' do
          expect(result[:status]).to eq(:success)

          project.reload
          expect(project.error_tracking_setting).not_to be_enabled
          expect(project.error_tracking_setting.integrated).to be_truthy
          expect(project.error_tracking_setting.api_url).to eq(
            'http://gitlab.com/api/0/projects/org/project/'
          )
          expect(project.error_tracking_setting.token).to eq('token')
          expect(project.error_tracking_setting[:project_name]).to eq('Project')
          expect(project.error_tracking_setting[:organization_name]).to eq('Org')
        end

        context 'disable error tracking' do
          before do
            params[:error_tracking_setting_attributes][:api_host] = ''
            params[:error_tracking_setting_attributes][:enabled] = false
          end

          it 'can set api_url to nil' do
            expect(result[:status]).to eq(:success)

            project.reload
            expect(project.error_tracking_setting).not_to be_enabled
            expect(project.error_tracking_setting.api_url).to be_nil
            expect(project.error_tracking_setting.token).to eq('token')
            expect(project.error_tracking_setting[:project_name]).to eq('Project')
            expect(project.error_tracking_setting[:organization_name]).to eq('Org')
          end
        end
      end

      context 'without an existing error tracking setting' do
        let(:params) do
          {
            error_tracking_setting_attributes: {
              enabled: true,
              integrated: true,
              api_host: 'http://gitlab.com/',
              token: 'token',
              project: {
                slug: 'project',
                name: 'Project',
                organization_slug: 'org',
                organization_name: 'Org'
              }
            }
          }
        end

        it 'creates a setting' do
          expect(result[:status]).to eq(:success)

          expect(project.error_tracking_setting).to be_enabled
          expect(project.error_tracking_setting.integrated).to be_truthy
          expect(project.error_tracking_setting.api_url).to eq(
            'http://gitlab.com/api/0/projects/org/project/'
          )
          expect(project.error_tracking_setting.token).to eq('token')
          expect(project.error_tracking_setting[:project_name]).to eq('Project')
          expect(project.error_tracking_setting[:organization_name]).to eq('Org')
        end
      end

      context 'partial_update' do
        let(:params) do
          {
            error_tracking_setting_attributes: {
              enabled: true
            }
          }
        end

        context 'with setting' do
          before do
            create(:project_error_tracking_setting, :disabled, project: project)
          end

          it 'service succeeds' do
            expect(result[:status]).to eq(:success)
          end

          it 'updates attributes' do
            expect { result }
              .to change { project.reload.error_tracking_setting.enabled }
              .from(false)
              .to(true)
          end

          it 'only updates enabled attribute' do
            result

            expect(project.error_tracking_setting.previous_changes.keys)
              .to contain_exactly('enabled')
          end

          context 'with integrated attribute' do
            let(:params) do
              {
                error_tracking_setting_attributes: {
                  enabled: true,
                  integrated: true
                }
              }
            end

            it 'updates integrated attribute' do
              expect { result }
                .to change { project.reload.error_tracking_setting.integrated }
                .from(false)
                .to(true)
            end

            it 'only updates enabled and integrated attributes' do
              result

              expect(project.error_tracking_setting.previous_changes.keys)
                .to contain_exactly('enabled', 'integrated')
            end
          end
        end

        context 'without setting' do
          it 'creates setting with default values' do
            expect(result[:status]).to eq(:success)
            expect(project.error_tracking_setting.enabled).to be_truthy
            expect(project.error_tracking_setting.integrated).to be_truthy
          end
        end
      end

      context 'with masked param token' do
        let(:params) do
          {
            error_tracking_setting_attributes: {
              api_host: 'https://sentrytest.gitlab.com/',
              project: {
                slug: 'sentry-project',
                organization_slug: 'sentry-org'
              },
              enabled: false,
              token: '*' * 8
            }
          }
        end

        before do
          create(:project_error_tracking_setting, project: project, token: 'token', api_url: 'https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project/')
        end

        it 'does not update token' do
          expect(result[:status]).to eq(:success)

          expect(project.error_tracking_setting.token).to eq('token')
        end
      end

      context 'with invalid parameters' do
        let(:params) { {} }

        let!(:error_tracking_setting) do
          create(:project_error_tracking_setting, project: project)
        end

        it 'does nothing' do
          expect(result[:status]).to eq(:success)
          expect(project.reload.error_tracking_setting)
            .to eq(error_tracking_setting)
        end
      end
    end

    context 'with inappropriate params' do
      let(:params) { { name: '' } }

      let!(:original_name) { project.name }

      it 'ignores params' do
        expect(result[:status]).to eq(:success)
        expect(project.reload.name).to eq(original_name)
      end
    end
  end
end
