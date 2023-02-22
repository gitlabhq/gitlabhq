# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::CreateRunnerService, "#execute", feature_category: :runner_fleet do
  subject(:execute) { described_class.new(user: current_user, type: type, params: params).execute }

  let(:runner) { execute.payload[:runner] }

  let_it_be(:admin) { create(:admin) }
  let_it_be(:non_admin_user) { create(:user) }
  let_it_be(:anonymous) { nil }

  shared_context 'when admin user' do
    let(:current_user) { admin }

    before do
      allow(current_user).to receive(:can?).with(:create_instance_runners).and_return true
    end
  end

  shared_examples 'it can create a runner' do
    it 'creates a runner of the specified type' do
      expect(runner.runner_type).to eq expected_type
    end

    context 'with default params provided' do
      let(:args) do
        {}
      end

      before do
        params.merge!(args)
      end

      it { is_expected.to be_success }

      it 'uses default values when none are provided' do
        expect(runner).to be_an_instance_of(::Ci::Runner)
        expect(runner.persisted?).to be_truthy
        expect(runner.run_untagged).to be true
        expect(runner.active).to be true
        expect(runner.creator).to be current_user
        expect(runner.authenticated_user_registration_type?).to be_truthy
        expect(runner.runner_type).to eq 'instance_type'
      end
    end

    context 'with non-default params provided' do
      let(:args) do
        {
          description: 'some description',
          maintenance_note: 'a note',
          paused: true,
          tag_list: %w[tag1 tag2],
          access_level: 'ref_protected',
          locked: true,
          maximum_timeout: 600,
          run_untagged: false
        }
      end

      before do
        params.merge!(args)
      end

      it { is_expected.to be_success }

      it 'creates runner with specified values', :aggregate_failures do
        expect(runner).to be_an_instance_of(::Ci::Runner)
        expect(runner.description).to eq 'some description'
        expect(runner.maintenance_note).to eq 'a note'
        expect(runner.active).to eq !args[:paused]
        expect(runner.locked).to eq args[:locked]
        expect(runner.run_untagged).to eq args[:run_untagged]
        expect(runner.tags).to contain_exactly(
          an_object_having_attributes(name: 'tag1'),
          an_object_having_attributes(name: 'tag2')
        )
        expect(runner.access_level).to eq args[:access_level]
        expect(runner.maximum_timeout).to eq args[:maximum_timeout]

        expect(runner.authenticated_user_registration_type?).to be_truthy
        expect(runner.runner_type).to eq 'instance_type'
      end

      context 'with a nil paused value' do
        let(:args) do
          {
            paused: nil,
            description: 'some description',
            maintenance_note: 'a note',
            tag_list: %w[tag1 tag2],
            access_level: 'ref_protected',
            locked: true,
            maximum_timeout: 600,
            run_untagged: false
          }
        end

        it { is_expected.to be_success }

        it 'creates runner with active set to true' do
          expect(runner).to be_an_instance_of(::Ci::Runner)
          expect(runner.active).to eq true
        end
      end

      context 'with no paused value given' do
        let(:args) do
          {
            description: 'some description',
            maintenance_note: 'a note',
            tag_list: %w[tag1 tag2],
            access_level: 'ref_protected',
            locked: true,
            maximum_timeout: 600,
            run_untagged: false
          }
        end

        it { is_expected.to be_success }

        it 'creates runner with active set to true' do
          expect(runner).to be_an_instance_of(::Ci::Runner)
          expect(runner.active).to eq true
        end
      end
    end
  end

  shared_examples 'it cannot create a runner' do
    it 'runner payload is nil' do
      expect(runner).to be nil
    end

    it { is_expected.to be_error }
  end

  shared_examples 'it can return an error' do
    let(:group) { create(:group) }
    let(:runner_double) { Ci::Runner.new }

    context 'when the runner fails to save' do
      before do
        allow(Ci::Runner).to receive(:new).and_return runner_double
      end

      it_behaves_like 'it cannot create a runner'

      it 'returns error message' do
        expect(execute.errors).not_to be_empty
      end
    end
  end

  context 'with type param set to nil' do
    let(:expected_type) { 'instance_type' }
    let(:type) { nil }
    let(:params) { {} }

    it_behaves_like 'it cannot create a runner' do
      let(:current_user) { anonymous }
    end

    it_behaves_like 'it cannot create a runner' do
      let(:current_user) { non_admin_user }
    end

    it_behaves_like 'it can create a runner' do
      include_context 'when admin user'
    end

    it_behaves_like 'it can return an error' do
      include_context 'when admin user'
    end
  end
end
