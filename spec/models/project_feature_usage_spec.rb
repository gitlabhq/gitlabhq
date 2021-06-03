# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectFeatureUsage, type: :model do
  describe '.jira_dvcs_integrations_enabled_count' do
    it 'returns count of projects with Jira DVCS Cloud enabled' do
      create(:project).feature_usage.log_jira_dvcs_integration_usage
      create(:project).feature_usage.log_jira_dvcs_integration_usage

      expect(described_class.with_jira_dvcs_integration_enabled.count).to eq(2)
    end

    it 'returns count of projects with Jira DVCS Server enabled' do
      create(:project).feature_usage.log_jira_dvcs_integration_usage(cloud: false)
      create(:project).feature_usage.log_jira_dvcs_integration_usage(cloud: false)

      expect(described_class.with_jira_dvcs_integration_enabled(cloud: false).count).to eq(2)
    end
  end

  describe '#log_jira_dvcs_integration_usage' do
    let(:project) { create(:project) }

    subject { project.feature_usage }

    context 'when the feature usage has not been created yet' do
      it 'logs Jira DVCS Cloud last sync' do
        freeze_time do
          subject.log_jira_dvcs_integration_usage

          expect(subject.jira_dvcs_server_last_sync_at).to be_nil
          expect(subject.jira_dvcs_cloud_last_sync_at).to be_like_time(Time.current)
        end
      end

      it 'logs Jira DVCS Server last sync' do
        freeze_time do
          subject.log_jira_dvcs_integration_usage(cloud: false)

          expect(subject.jira_dvcs_server_last_sync_at).to be_like_time(Time.current)
          expect(subject.jira_dvcs_cloud_last_sync_at).to be_nil
        end
      end
    end

    context 'when the feature usage already exists' do
      let(:today) { Time.current.beginning_of_day }
      let(:project) { create(:project) }

      subject { project.feature_usage }

      where(:cloud, :timestamp_field) do
        [
          [true, :jira_dvcs_cloud_last_sync_at],
          [false, :jira_dvcs_server_last_sync_at]
        ]
      end

      with_them do
        context 'when Jira DVCS Cloud last sync has not been logged' do
          before do
            travel_to today - 3.days do
              subject.log_jira_dvcs_integration_usage(cloud: !cloud)
            end
          end

          it 'logs Jira DVCS Cloud last sync' do
            freeze_time do
              subject.log_jira_dvcs_integration_usage(cloud: cloud)

              expect(subject.reload.send(timestamp_field)).to be_like_time(Time.current)
            end
          end
        end

        context 'when Jira DVCS Cloud last sync was logged today' do
          let(:last_updated) { today + 1.hour }

          before do
            travel_to last_updated do
              subject.log_jira_dvcs_integration_usage(cloud: cloud)
            end
          end

          it 'does not log Jira DVCS Cloud last sync' do
            travel_to today + 2.hours do
              subject.log_jira_dvcs_integration_usage(cloud: cloud)

              expect(subject.reload.send(timestamp_field)).to be_like_time(last_updated)
            end
          end
        end

        context 'when Jira DVCS Cloud last sync was logged yesterday' do
          let(:last_updated) { today - 2.days }

          before do
            travel_to last_updated do
              subject.log_jira_dvcs_integration_usage(cloud: cloud)
            end
          end

          it 'logs Jira DVCS Cloud last sync' do
            travel_to today + 1.hour do
              subject.log_jira_dvcs_integration_usage(cloud: cloud)

              expect(subject.reload.send(timestamp_field)).to be_like_time(today + 1.hour)
            end
          end
        end
      end
    end

    context 'when log_jira_dvcs_integration_usage is called simultaneously for the same project' do
      it 'logs the latest call' do
        feature_usage = project.feature_usage
        feature_usage.log_jira_dvcs_integration_usage
        first_logged_at = feature_usage.jira_dvcs_cloud_last_sync_at

        travel_to(1.hour.from_now) do
          ProjectFeatureUsage.new(project_id: project.id).log_jira_dvcs_integration_usage
        end

        expect(feature_usage.reload.jira_dvcs_cloud_last_sync_at).to be > first_logged_at
      end
    end
  end

  context 'ProjectFeatureUsage with DB Load Balancing', :request_store do
    include_context 'clear DB Load Balancing configuration'

    describe '#log_jira_dvcs_integration_usage' do
      let!(:project) { create(:project) }

      subject { project.feature_usage }

      context 'database load balancing is configured' do
        before do
          # Do not pollute AR for other tests, but rather simulate effect of configure_proxy.
          allow(ActiveRecord::Base.singleton_class).to receive(:prepend)
          ::Gitlab::Database::LoadBalancing.configure_proxy
          allow(ActiveRecord::Base).to receive(:connection).and_return(::Gitlab::Database::LoadBalancing.proxy)
          ::Gitlab::Database::LoadBalancing::Session.clear_session
        end

        it 'logs Jira DVCS Cloud last sync' do
          freeze_time do
            subject.log_jira_dvcs_integration_usage

            expect(subject.jira_dvcs_server_last_sync_at).to be_nil
            expect(subject.jira_dvcs_cloud_last_sync_at).to be_like_time(Time.current)
          end
        end

        it 'does not stick to primary' do
          expect(::Gitlab::Database::LoadBalancing::Session.current).not_to be_performed_write
          expect(::Gitlab::Database::LoadBalancing::Session.current).not_to be_using_primary

          subject.log_jira_dvcs_integration_usage

          expect(::Gitlab::Database::LoadBalancing::Session.current).to be_performed_write
          expect(::Gitlab::Database::LoadBalancing::Session.current).not_to be_using_primary
        end
      end

      context 'database load balancing is not cofigured' do
        it 'logs Jira DVCS Cloud last sync' do
          freeze_time do
            subject.log_jira_dvcs_integration_usage

            expect(subject.jira_dvcs_server_last_sync_at).to be_nil
            expect(subject.jira_dvcs_cloud_last_sync_at).to be_like_time(Time.current)
          end
        end
      end
    end
  end
end
