# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Context do
  let(:project) { double('Project') }
  let(:user) { double('User') }
  let(:sha) { '12345' }
  let(:attributes) { { project: project, user: user, sha: sha } }

  subject(:subject) { described_class.new(**attributes) }

  describe 'attributes' do
    context 'with values' do
      it { is_expected.to have_attributes(**attributes) }
      it { expect(subject.expandset).to eq(Set.new) }
      it { expect(subject.execution_deadline).to eq(0) }
    end

    context 'without values' do
      let(:attributes) { { project: nil, user: nil, sha: nil } }

      it { is_expected.to have_attributes(**attributes) }
      it { expect(subject.expandset).to eq(Set.new) }
      it { expect(subject.execution_deadline).to eq(0) }
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
    end

    context 'with attributes' do
      let(:new_attributes) { { project: double, user: double, sha: '56789' } }

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
end
