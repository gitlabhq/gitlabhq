# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::ExperimentTracking::ExperimentRepository, feature_category: :activation do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:experiment) { create(:ml_experiments, user: user, project: project) }
  let_it_be(:experiment2) { create(:ml_experiments, user: user, project: project) }
  let_it_be(:experiment3) { create(:ml_experiments, user: user, project: project) }
  let_it_be(:experiment4) { create(:ml_experiments, user: user) }

  let(:repository) { described_class.new(project, user) }

  describe '#by_iid_or_name' do
    let(:iid) { experiment.iid }
    let(:name) { nil }

    subject { repository.by_iid_or_name(iid: iid, name: name) }

    context 'when iid passed' do
      it('fetches the experiment') { is_expected.to eq(experiment) }

      context 'and name passed' do
        let(:name) { experiment2.name }

        it('ignores the name') { is_expected.to eq(experiment) }
      end

      context 'and does not exist' do
        let(:iid) { non_existing_record_iid }

        it { is_expected.to eq(nil) }
      end
    end

    context 'when iid is not passed', 'and name is passed' do
      let(:iid) { nil }

      context 'when name exists' do
        let(:name) { experiment2.name }

        it('fetches the experiment') { is_expected.to eq(experiment2) }
      end

      context 'when name does not exist' do
        let(:name) { non_existing_record_iid }

        it { is_expected.to eq(nil) }
      end
    end
  end

  describe '#all' do
    it 'fetches experiments for project' do
      expect(repository.all).to match_array([experiment, experiment2, experiment3])
    end
  end

  describe '#create!' do
    let(:name) { 'hello' }
    let(:tags) { nil }

    subject { repository.create!(name, tags) }

    it 'creates the experiment' do
      expect { subject }.to change { repository.all.size }.by(1)
    end

    context 'when name exists' do
      let(:name) { experiment.name }

      it 'throws error' do
        expect { subject }.to raise_error(ActiveRecord::ActiveRecordError)
      end
    end

    context 'when has tags' do
      let(:tags) { [{ key: 'hello', value: 'world' }] }

      it 'creates the experiment with tag' do
        expect(subject.metadata.length).to eq(1)
      end
    end

    context 'when name is missing' do
      let(:name) { nil }

      it 'throws error' do
        expect { subject }.to raise_error(ActiveRecord::ActiveRecordError)
      end
    end
  end

  describe '#add_tag!' do
    let(:props) { { name: 'abc', value: 'def' } }

    subject { repository.add_tag!(experiment, props[:name], props[:value]) }

    it 'adds a new tag' do
      expect { subject }.to change { experiment.reload.metadata.size }.by(1)
    end

    context 'when name missing' do
      let(:props) { { value: 1234 } }

      it 'throws RecordInvalid' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when tag was already added' do
      it 'throws RecordInvalid' do
        repository.add_tag!(experiment, 'new', props[:value])

        expect { repository.add_tag!(experiment, 'new', props[:value]) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
