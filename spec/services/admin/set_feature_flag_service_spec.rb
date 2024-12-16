# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::SetFeatureFlagService, feature_category: :feature_flags do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }

  let(:feature_name) { known_feature_flag.name }
  let(:service) { described_class.new(feature_flag_name: feature_name, params: params) }

  # Find any `development` feature flag name
  let(:known_feature_flag) do
    Feature::Definition.definitions
      .values.find { |defn| defn.development? && !defn.default_enabled }
  end

  describe 'sequences of executions' do
    subject(:flag) do
      Feature.get(feature_name) # rubocop: disable Gitlab/AvoidFeatureGet
    end

    context 'if we enable_percentage_of_actors and then disable' do
      before do
        described_class
          .new(feature_flag_name: feature_name, params: { key: 'percentage_of_actors', value: '50.0' })
           .execute

        described_class
          .new(feature_flag_name: feature_name, params: { key: 'percentage_of_actors', value: '0.0' })
          .execute
      end

      it 'leaves the flag off' do
        expect(flag.state).to eq(:off)
      end
    end

    context 'if we enable and then enable_percentage_of_actors' do
      before do
        described_class
          .new(feature_flag_name: feature_name, params: { key: 'percentage_of_actors', value: '100.0' })
          .execute
      end

      it 'reports an error' do
        result = described_class
            .new(feature_flag_name: feature_name, params: { key: 'percentage_of_actors', value: '50.0' })
            .execute

        expect(flag.state).to eq(:on)
        expect(result).to be_error
      end

      context 'if we disable the flag first' do
        before do
          described_class
            .new(feature_flag_name: feature_name, params: { value: 'false' })
            .execute
        end

        it 'sets the percentage of actors' do
          result = described_class
              .new(feature_flag_name: feature_name, params: { key: 'percentage_of_actors', value: '50.0' })
              .execute

          expect(flag.state).to eq(:conditional)
          expect(result).not_to be_error
        end
      end
    end
  end

  describe '#execute' do
    before do
      unstub_all_feature_flags

      Feature.reset
      Flipper.unregister_groups
      Flipper.register(:perf_team) do |actor|
        actor.respond_to?(:admin) && actor.admin?
      end
    end

    subject(:result) { service.execute }

    context 'when we cannot interpret the operation' do
      let(:params) { { value: 'wibble', key: 'unknown' } }

      it { is_expected.to be_error }
      it { is_expected.to have_attributes(reason: :illegal_operation) }
      it { is_expected.to have_attributes(message: %(Cannot set '#{feature_name}' ("unknown") to "wibble")) }

      context 'when the key is absent' do
        let(:params) { { value: 'wibble' } }

        it { is_expected.to be_error }
        it { is_expected.to have_attributes(reason: :illegal_operation) }
        it { is_expected.to have_attributes(message: %(Cannot set '#{feature_name}' to "wibble")) }
      end
    end

    context 'when the value to set cannot be parsed' do
      let(:params) { { value: 'wibble', key: 'percentage_of_actors' } }

      it { is_expected.to be_error }
      it { is_expected.to have_attributes(reason: :illegal_operation) }
      it { is_expected.to have_attributes(message: 'Not a percentage') }
    end

    context 'when value is "remove_opt_out"' do
      before do
        Feature.enable(feature_name)
      end

      context 'without a target' do
        let(:params) { { value: 'remove_opt_out' } }

        it 'returns an error' do
          expect(result).to be_error
          expect(result.reason).to eq(:illegal_operation)
        end
      end

      context 'with a target' do
        let(:params) { { value: 'remove_opt_out', user: user.username } }

        context 'when there is currently no opt-out' do
          it 'returns an error' do
            expect(result).to be_error
            expect(result.reason).to eq(:illegal_operation)
            expect(Feature).to be_enabled(feature_name, user)
          end
        end

        context 'when there is currently an opt-out' do
          before do
            Feature.opt_out(feature_name, user)
          end

          it 'removes the opt out' do
            expect(result).to be_success
            expect(Feature).to be_enabled(feature_name, user)
          end
        end
      end
    end

    context 'when value is "opt_out"' do
      let(:params) { { value: 'opt_out', namespace: group.full_path, user: user.username } }

      it 'opts the user and group out' do
        expect(Feature).to receive(:opt_out).with(feature_name, user)
        expect(Feature).to receive(:opt_out).with(feature_name, group)
        expect(result).to be_success
      end

      context 'without a target' do
        let(:params) { { value: 'opt_out' } }

        it { is_expected.to be_error }

        it { is_expected.to have_attributes(reason: :illegal_operation) }
      end
    end

    context 'when enabling the feature flag' do
      let(:params) { { value: 'true' } }

      it 'enables the feature flag' do
        expect(Feature).to receive(:enable).with(feature_name)
        expect(subject).to be_success

        feature_flag = subject.payload[:feature_flag]
        expect(feature_flag.name).to eq(feature_name)
      end

      context 'when the flag is default_enabled' do
        let(:known_feature_flag) do
          Feature::Definition.definitions
            .values.find { |defn| defn.development? && defn.default_enabled }
        end

        it 'leaves the flag enabled' do
          expect(subject).to be_success
          expect(Feature).to be_enabled(feature_name)
        end
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

        context 'when the flag has been opted out for user' do
          before do
            Feature.enable(feature_name)
            Feature.opt_out(feature_name, user)
          end

          it 'records an error' do
            expect(subject).to be_error
            expect(subject.reason).to eq(:illegal_operation)
            expect(Feature).not_to be_enabled(feature_name, user)
          end
        end

        context 'when the flag is default_enabled' do
          let(:known_feature_flag) do
            Feature::Definition.definitions
              .values.find { |defn| defn.development? && defn.default_enabled }
          end

          it 'leaves the feature enabled' do
            expect(subject).to be_success
            expect(Feature).to be_enabled(feature_name, user)
          end
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

      context 'when enabling for a project namespace' do
        let(:project_namespace) { create(:project_namespace) }
        let(:params) { { value: 'true', namespace: project_namespace.full_path } }

        it 'returns an error' do
          expect(Feature).not_to receive(:disable)
          expect(subject).to be_error
          expect(subject.reason).to eq(:actor_not_found)
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

      context 'when enabling for multiple actors' do
        let_it_be(:actor1) { group }
        let_it_be(:actor2) { create(:group) }

        context 'when passed as comma separated string' do
          let(:params) { { value: 'true', group: "#{actor1.full_path},#{actor2.full_path}" } }

          it 'enables the feature flag for all actors' do
            expect(Feature).to receive(:enable).with(feature_name, actor1)
            expect(Feature).to receive(:enable).with(feature_name, actor2)
            expect(subject).to be_success
          end
        end

        context 'when empty value exists between comma' do
          let(:params) { { value: 'true', group: "#{actor1.full_path},#{actor2.full_path},,," } }

          it 'enables the feature flag for all actors' do
            expect(Feature).to receive(:enable).with(feature_name, actor1)
            expect(Feature).to receive(:enable).with(feature_name, actor2)
            expect(subject).to be_success
          end
        end

        context 'when one of the actors does not exist' do
          let(:params) { { value: 'true', group: "#{actor1.full_path},nonexistent-actor" } }

          it 'does not enable the feature flags' do
            expect(Feature).not_to receive(:enable)
            expect(subject).to be_error
            expect(subject.message).to eq('nonexistent-actor is not found!')
          end
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

        context 'with a target' do
          before do
            params[:user] = user.username
          end

          it { is_expected.to be_error }

          it { is_expected.to have_attributes(reason: :illegal_operation) }
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

        context 'with a target' do
          before do
            params[:user] = user.username
          end

          it { is_expected.to be_error }

          it { is_expected.to have_attributes(reason: :illegal_operation) }
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

        context 'when project does not exist' do
          let(:params) { { value: 'false', project: 'unknown-project' } }

          it 'returns an error' do
            expect(Feature).not_to receive(:disable)
            expect(subject).to be_error
            expect(subject.reason).to eq(:actor_not_found)
          end
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
