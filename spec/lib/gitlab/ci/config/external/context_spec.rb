# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Context, feature_category: :pipeline_composition do
  let(:project) { build(:project) }
  let(:pipeline) { double('Pipeline') }
  let(:user) { double('User') }
  let(:sha) { '12345' }
  let(:variables) { Gitlab::Ci::Variables::Collection.new([{ 'key' => 'a', 'value' => 'b' }]) }
  let(:pipeline_config) { instance_double(Gitlab::Ci::ProjectConfig) }
  let(:attributes) do
    {
      project: project,
      pipeline: pipeline,
      user: user,
      sha: sha,
      variables: variables,
      pipeline_config: pipeline_config
    }
  end

  subject(:subject) { described_class.new(**attributes) }

  describe 'attributes' do
    context 'with values' do
      it { is_expected.to have_attributes(**attributes) }
      it { expect(subject.expandset).to eq([]) }
      it { expect(subject.execution_deadline).to eq(0) }
      it { expect(subject.variables).to be_instance_of(Gitlab::Ci::Variables::Collection) }
      it { expect(subject.variables_hash).to be_instance_of(ActiveSupport::HashWithIndifferentAccess) }
      it { expect(subject.variables_hash).to include('a' => 'b') }
      it { expect(subject.pipeline_config).to eq(pipeline_config) }
    end

    context 'without values' do
      let(:attributes) { { project: nil, pipeline: nil, user: nil, sha: nil } }

      it { is_expected.to have_attributes(**attributes) }
      it { expect(subject.expandset).to eq([]) }
      it { expect(subject.execution_deadline).to eq(0) }
      it { expect(subject.variables).to be_instance_of(Gitlab::Ci::Variables::Collection) }
      it { expect(subject.variables_hash).to be_instance_of(ActiveSupport::HashWithIndifferentAccess) }
      it { expect(subject.pipeline_config).to be_nil }
    end

    describe 'max_includes' do
      it 'returns the default value of application setting `ci_max_includes`' do
        expect(subject.max_includes).to eq(150)
      end

      context 'when application setting `ci_max_includes` is changed' do
        before do
          stub_application_setting(ci_max_includes: 200)
        end

        it 'returns the new value of application setting `ci_max_includes`' do
          expect(subject.max_includes).to eq(200)
        end
      end
    end

    describe 'max_total_yaml_size_bytes' do
      context 'when application setting `max_total_yaml_size_bytes` is requsted and was never updated by the admin' do
        it 'returns the default value `max_total_yaml_size_bytes`' do
          expect(subject.max_total_yaml_size_bytes).to eq(314572800)
        end
      end

      context 'when `max_total_yaml_size_bytes` was adjusted by the admin' do
        before do
          stub_application_setting(ci_max_total_yaml_size_bytes: 200000000)
        end

        it 'returns the updated value of application setting `max_total_yaml_size_bytes`' do
          expect(subject.max_total_yaml_size_bytes).to eq(200000000)
        end
      end
    end
  end

  describe '#set_deadline' do
    let(:stubbed_time) { 1 }

    before do
      allow(subject).to receive(:current_monotonic_time).and_return(stubbed_time)
    end

    context 'with a float value' do
      let(:timeout_seconds) { 10.5.seconds }

      it 'updates execution_deadline' do
        expect { subject.set_deadline(timeout_seconds) }
          .to change { subject.execution_deadline }
          .to(timeout_seconds + stubbed_time)
      end
    end

    context 'with nil as a value' do
      let(:timeout_seconds) {}

      it 'updates execution_deadline' do
        expect { subject.set_deadline(timeout_seconds) }
          .to change { subject.execution_deadline }
          .to(stubbed_time)
      end
    end
  end

  describe '#check_execution_time!' do
    before do
      allow(subject).to receive(:current_monotonic_time).and_return(stubbed_time)
      allow(subject).to receive(:execution_deadline).and_return(stubbed_deadline)
    end

    context 'when execution is expired' do
      let(:stubbed_time) { 2 }
      let(:stubbed_deadline) { 1 }

      it 'raises an error' do
        expect { subject.check_execution_time! }
          .to raise_error(described_class::TimeoutError)
      end
    end

    context 'when execution is not expired' do
      let(:stubbed_time) { 1 }
      let(:stubbed_deadline) { 2 }

      it 'does not raises any errors' do
        expect { subject.check_execution_time! }.not_to raise_error
      end
    end

    context 'without setting a deadline' do
      let(:stubbed_time) { 2 }
      let(:stubbed_deadline) { 1 }

      before do
        allow(subject).to receive(:execution_deadline).and_call_original
      end

      it 'does not raises any errors' do
        expect { subject.check_execution_time! }.not_to raise_error
      end
    end
  end

  describe '#mutate' do
    let(:attributes) do
      {
        project: project,
        pipeline: pipeline,
        user: user,
        sha: sha,
        logger: double('logger')
      }
    end

    shared_examples 'a mutated context' do
      let(:mutated) { subject.mutate(new_attributes) }
      let(:lazy_response) { double('lazy_response') }

      before do
        allow(lazy_response).to receive(:execute).and_return(lazy_response)

        subject.expandset << :a_file
        subject.set_deadline(15.seconds)
        subject.execute_remote_parallel_request(lazy_response)
      end

      it { expect(mutated).not_to eq(subject) }
      it { expect(mutated).to be_a(described_class) }
      it { expect(mutated).to have_attributes(new_attributes) }
      it { expect(mutated.pipeline).to eq(subject.pipeline) }
      it { expect(mutated.expandset).to eq(subject.expandset) }
      it { expect(mutated.execution_deadline).to eq(subject.execution_deadline) }
      it { expect(mutated.logger).to eq(subject.logger) }
      it { expect(mutated.parallel_requests).to eq(subject.parallel_requests) }
    end

    context 'with attributes' do
      let(:new_attributes) { { project: build(:project), user: double, sha: '56789' } }

      it_behaves_like 'a mutated context'
    end

    context 'without attributes' do
      let(:new_attributes) { {} }

      it_behaves_like 'a mutated context'
    end
  end

  describe '#sentry_payload' do
    it { expect(subject.sentry_payload).to match(a_hash_including(:project, :user)) }
  end

  describe '#internal_include?' do
    context 'when pipeline_config is provided' do
      where(:value) { [true, false] }

      with_them do
        it 'returns the value of .internal_include_prepended?' do
          allow(pipeline_config).to receive(:internal_include_prepended?).and_return(value)

          expect(subject.internal_include?).to eq(value)
        end
      end
    end

    context 'when pipeline_config is not provided' do
      let(:pipeline_config) { nil }

      it 'returns false' do
        expect(subject.internal_include?).to eq(false)
      end
    end
  end

  describe '#execute_remote_parallel_request' do
    let(:lazy_response1) { double('lazy_response', wait: true, complete?: complete1) }
    let(:lazy_response2) { double('lazy_response') }

    let(:complete1) { false }

    before do
      allow(lazy_response1).to receive(:execute).and_return(lazy_response1)
      allow(lazy_response2).to receive(:execute).and_return(lazy_response2)
    end

    context 'when the queue is empty' do
      before do
        stub_const("Gitlab::Ci::Config::External::Context::MAX_PARALLEL_REMOTE_REQUESTS", 2)
      end

      it 'adds the new lazy response to the queue' do
        expect { subject.execute_remote_parallel_request(lazy_response1) }
          .to change { subject.parallel_requests }
          .from([])
          .to([lazy_response1])
      end
    end

    context 'when there is a lazy response in the queue' do
      before do
        subject.execute_remote_parallel_request(lazy_response1)
      end

      context 'when there is a free slot in the queue' do
        before do
          stub_const("Gitlab::Ci::Config::External::Context::MAX_PARALLEL_REMOTE_REQUESTS", 2)
        end

        it 'adds the new lazy response to the queue' do
          expect { subject.execute_remote_parallel_request(lazy_response2) }
            .to change { subject.parallel_requests }
            .from([lazy_response1])
            .to([lazy_response1, lazy_response2])
        end
      end

      context 'when the queue is full' do
        before do
          stub_const("Gitlab::Ci::Config::External::Context::MAX_PARALLEL_REMOTE_REQUESTS", 1)
        end

        context 'when the first lazy response in the queue is complete' do
          let(:complete1) { true }

          it 'removes the completed lazy response and adds the new one to the queue' do
            expect(lazy_response1).not_to receive(:wait)

            expect { subject.execute_remote_parallel_request(lazy_response2) }
              .to change { subject.parallel_requests }
              .from([lazy_response1])
              .to([lazy_response2])
          end
        end

        context 'when the first lazy response in the queue is not complete' do
          let(:complete1) { false }

          it 'waits for the first lazy response to complete and then adds the new one to the queue' do
            expect(lazy_response1).to receive(:wait)

            expect { subject.execute_remote_parallel_request(lazy_response2) }
              .to change { subject.parallel_requests }
              .from([lazy_response1])
              .to([lazy_response1, lazy_response2])
          end
        end
      end
    end
  end
end
