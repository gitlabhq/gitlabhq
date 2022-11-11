# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::SetFeatureFlagService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }

  let(:feature_name) { known_feature_flag.name }
  let(:service) { described_class.new(feature_flag_name: feature_name, params: params) }

  # Find any `development` feature flag name
  let(:known_feature_flag) do
    Feature::Definition.definitions
      .values.find(&:development?)
  end

  describe '#execute' do
    before do
      Feature.reset
      Flipper.unregister_groups
      Flipper.register(:perf_team) do |actor|
        actor.respond_to?(:admin) && actor.admin?
      end
    end

    subject { service.execute }

    context 'when enabling the feature flag' do
      let(:params) { { value: 'true' } }

      it 'enables the feature flag' do
        expect(Feature).to receive(:enable).with(feature_name)
        expect(subject).to be_success

        feature_flag = subject.payload[:feature_flag]
        expect(feature_flag.name).to eq(feature_name)
      end

      it 'logs the event' do
        expect(Feature.logger).to receive(:info).once

        subject
      end

      context 'when enabling for a user actor' do
        let(:params) { { value: 'true', user: user.username } }

        it 'enables the feature flag' do
          expect(Feature).to receive(:enable).with(feature_name, user)
          expect(subject).to be_success
        end

        context 'when user does not exist' do
          let(:params) { { value: 'true', user: 'unknown-user' } }

          it 'does nothing' do
            expect(Feature).not_to receive(:enable)
            expect(subject).to be_error
            expect(subject.reason).to eq(:actor_not_found)
          end
        end
      end

      context 'when enabling for a feature group' do
        let(:params) { { value: 'true', feature_group: 'perf_team' } }
        let(:feature_group) { Feature.group('perf_team') }

        it 'enables the feature flag' do
          expect(Feature).to receive(:enable).with(feature_name, feature_group)
          expect(subject).to be_success
        end
      end

      context 'when enabling for a project' do
        let(:params) { { value: 'true', project: project.full_path } }

        it 'enables the feature flag' do
          expect(Feature).to receive(:enable).with(feature_name, project)
          expect(subject).to be_success
        end
      end

      context 'when enabling for a group' do
        let(:params) { { value: 'true', group: group.full_path } }

        it 'enables the feature flag' do
          expect(Feature).to receive(:enable).with(feature_name, group)
          expect(subject).to be_success
        end

        context 'when group does not exist' do
          let(:params) { { value: 'true', group: 'unknown-group' } }

          it 'returns an error' do
            expect(Feature).not_to receive(:disable)
            expect(subject).to be_error
            expect(subject.reason).to eq(:actor_not_found)
          end
        end
      end

      context 'when enabling for a user namespace' do
        let(:namespace) { user.namespace }
        let(:params) { { value: 'true', namespace: namespace.full_path } }

        it 'enables the feature flag' do
          expect(Feature).to receive(:enable).with(feature_name, namespace)
          expect(subject).to be_success
        end

        context 'when namespace does not exist' do
          let(:params) { { value: 'true', namespace: 'unknown-namespace' } }

          it 'returns an error' do
            expect(Feature).not_to receive(:disable)
            expect(subject).to be_error
            expect(subject.reason).to eq(:actor_not_found)
          end
        end
      end

      context 'when enabling for a group namespace' do
        let(:params) { { value: 'true', namespace: group.full_path } }

        it 'enables the feature flag' do
          expect(Feature).to receive(:enable).with(feature_name, group)
          expect(subject).to be_success
        end
      end

      context 'when enabling for a repository' do
        let(:params) { { value: 'true', repository: project.repository.full_path } }

        it 'enables the feature flag' do
          expect(Feature).to receive(:enable).with(feature_name, project.repository)
          expect(subject).to be_success
        end
      end

      context 'when enabling for a user actor and a feature group' do
        let(:params) { { value: 'true', user: user.username, feature_group: 'perf_team' } }
        let(:feature_group) { Feature.group('perf_team') }

        it 'enables the feature flag' do
          expect(Feature).to receive(:enable).with(feature_name, user)
          expect(Feature).to receive(:enable).with(feature_name, feature_group)
          expect(subject).to be_success
        end
      end

      context 'when enabling given a percentage of time' do
        let(:params) { { value: '50' } }

        it 'enables the feature flag' do
          expect(Feature).to receive(:enable_percentage_of_time).with(feature_name, 50)
          expect(subject).to be_success
        end

        context 'when value is a float' do
          let(:params) { { value: '0.01' } }

          it 'enables the feature flag' do
            expect(Feature).to receive(:enable_percentage_of_time).with(feature_name, 0.01)
            expect(subject).to be_success
          end
        end
      end

      context 'when enabling given a percentage of actors' do
        let(:params) { { value: '50', key: 'percentage_of_actors' } }

        it 'enables the feature flag' do
          expect(Feature).to receive(:enable_percentage_of_actors).with(feature_name, 50)
          expect(subject).to be_success
        end

        context 'when value is a float' do
          let(:params) { { value: '0.01', key: 'percentage_of_actors' } }

          it 'enables the feature flag' do
            expect(Feature).to receive(:enable_percentage_of_actors).with(feature_name, 0.01)
            expect(subject).to be_success
          end
        end
      end
    end

    context 'when disabling the feature flag' do
      before do
        Feature.enable(feature_name)
      end

      let(:params) { { value: 'false' } }

      it 'disables the feature flag' do
        expect(Feature).to receive(:disable).with(feature_name)
        expect(subject).to be_success

        feature_flag = subject.payload[:feature_flag]
        expect(feature_flag.name).to eq(feature_name)
      end

      it 'logs the event' do
        expect(Feature.logger).to receive(:info).once

        subject
      end

      context 'when disabling for a user actor' do
        let(:params) { { value: 'false', user: user.username } }

        it 'disables the feature flag' do
          expect(Feature).to receive(:disable).with(feature_name, user)
          expect(subject).to be_success
        end

        context 'when user does not exist' do
          let(:params) { { value: 'false', user: 'unknown-user' } }

          it 'returns an error' do
            expect(Feature).not_to receive(:disable)
            expect(subject).to be_error
            expect(subject.reason).to eq(:actor_not_found)
          end
        end
      end

      context 'when disabling for a feature group' do
        let(:params) { { value: 'false', feature_group: 'perf_team' } }
        let(:feature_group) { Feature.group('perf_team') }

        it 'disables the feature flag' do
          expect(Feature).to receive(:disable).with(feature_name, feature_group)
          expect(subject).to be_success
        end
      end

      context 'when disabling for a project' do
        let(:params) { { value: 'false', project: project.full_path } }

        it 'disables the feature flag' do
          expect(Feature).to receive(:disable).with(feature_name, project)
          expect(subject).to be_success
        end
      end

      context 'when disabling for a group' do
        let(:params) { { value: 'false', group: group.full_path } }

        it 'disables the feature flag' do
          expect(Feature).to receive(:disable).with(feature_name, group)
          expect(subject).to be_success
        end

        context 'when group does not exist' do
          let(:params) { { value: 'false', group: 'unknown-group' } }

          it 'returns an error' do
            expect(Feature).not_to receive(:disable)
            expect(subject).to be_error
            expect(subject.reason).to eq(:actor_not_found)
          end
        end
      end

      context 'when disabling for a user namespace' do
        let(:namespace) { user.namespace }
        let(:params) { { value: 'false', namespace: namespace.full_path } }

        it 'disables the feature flag' do
          expect(Feature).to receive(:disable).with(feature_name, namespace)
          expect(subject).to be_success
        end

        context 'when namespace does not exist' do
          let(:params) { { value: 'false', namespace: 'unknown-namespace' } }

          it 'returns an error' do
            expect(Feature).not_to receive(:disable)
            expect(subject).to be_error
            expect(subject.reason).to eq(:actor_not_found)
          end
        end
      end

      context 'when disabling for a group namespace' do
        let(:params) { { value: 'false', namespace: group.full_path } }

        it 'disables the feature flag' do
          expect(Feature).to receive(:disable).with(feature_name, group)
          expect(subject).to be_success
        end
      end

      context 'when disabling for a user actor and a feature group' do
        let(:params) { { value: 'false', user: user.username, feature_group: 'perf_team' } }
        let(:feature_group) { Feature.group('perf_team') }

        it 'disables the feature flag' do
          expect(Feature).to receive(:disable).with(feature_name, user)
          expect(Feature).to receive(:disable).with(feature_name, feature_group)
          expect(subject).to be_success
        end
      end
    end
  end
end
