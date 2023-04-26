# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Context, feature_category: :pipeline_composition do
  let(:project) { build(:project) }
  let(:user) { double('User') }
  let(:sha) { '12345' }
  let(:variables) { Gitlab::Ci::Variables::Collection.new([{ 'key' => 'a', 'value' => 'b' }]) }
  let(:pipeline_config) { instance_double(Gitlab::Ci::ProjectConfig) }
  let(:attributes) do
    {
      project: project,
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
      let(:attributes) { { project: nil, user: nil, sha: nil } }

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
        user: user,
        sha: sha,
        logger: double('logger')
      }
    end

    shared_examples 'a mutated context' do
      let(:mutated) { subject.mutate(new_attributes) }

      before do
        subject.expandset << :a_file
        subject.set_deadline(15.seconds)
      end

      it { expect(mutated).not_to eq(subject) }
      it { expect(mutated).to be_a(described_class) }
      it { expect(mutated).to have_attributes(new_attributes) }
      it { expect(mutated.expandset).to eq(subject.expandset) }
      it { expect(mutated.execution_deadline).to eq(mutated.execution_deadline) }
      it { expect(mutated.logger).to eq(mutated.logger) }
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
end
