# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ml::ExperimentTracking::CandidateRepository, feature_category: :activation do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:experiment) { create(:ml_experiments, user: user, project: project) }
  let_it_be(:candidate) { create(:ml_candidates, user: user, experiment: experiment, project: project) }

  let(:repository) { described_class.new(project, user) }

  describe '#by_eid' do
    let(:eid) { candidate.eid }

    subject { repository.by_eid(eid) }

    it { is_expected.to eq(candidate) }

    context 'when iid does not exist' do
      let(:eid) { non_existing_record_iid.to_s }

      it { is_expected.to be_nil }
    end

    context 'when iid belongs to a different project' do
      let(:repository) { described_class.new(create(:project), user) }

      it { is_expected.to be_nil }
    end
  end

  describe '#create!' do
    let(:tags) { [{ key: 'hello', value: 'world' }] }
    let(:name) { 'some_candidate' }

    subject { repository.create!(experiment, 1234, tags, name) }

    it 'creates the candidate' do
      expect(subject.start_time).to eq(1234)
      expect(subject.eid).not_to be_nil
      expect(subject.end_time).to be_nil
      expect(subject.name).to eq('some_candidate')
    end

    it 'creates with tag' do
      expect(subject.metadata.length).to eq(1)
    end

    context 'when name is passed as tag' do
      let(:tags) { [{ key: 'mlflow.runName', value: 'blah' }] }

      it 'ignores if name is not nil' do
        expect(subject.name).to eq('some_candidate')
      end

      context 'when name is nil' do
        let(:name) { nil }

        it 'sets the mlflow.runName as candidate name' do
          expect(subject.name).to eq('blah')
        end
      end

      context 'when name is nil and no mlflow.runName is not present' do
        let(:tags) { nil }
        let(:name) { nil }

        it 'gives the candidate a random name' do
          expect(subject.name).to match(/[a-z]+-[a-z]+-[a-z]+-\d+/)
        end
      end
    end
  end

  describe '#update' do
    let(:end_time) { 123456 }
    let(:status) { 'running' }

    subject { repository.update(candidate, status, end_time) }

    it { is_expected.to be_truthy }

    context 'when end_time is missing ' do
      let(:end_time) { nil }

      it { is_expected.to be_truthy }
    end

    context 'when status is wrong' do
      let(:status) { 's' }

      it 'fails assigning the value' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'when status is missing' do
      let(:status) { nil }

      it { is_expected.to be_truthy }
    end
  end

  describe '#add_metric!' do
    let(:props) { { name: 'abc', value: 1234, tracked: 12345678, step: 0 } }
    let(:metrics_before) { candidate.metrics.size }

    before do
      metrics_before
    end

    subject { repository.add_metric!(candidate, props[:name], props[:value], props[:tracked], props[:step]) }

    it 'adds a new metric' do
      expect { subject }.to change { candidate.metrics.size }.by(1)
    end

    context 'when name missing' do
      let(:props) { { value: 1234, tracked: 12345678, step: 0 } }

      it 'does not add metric' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe '#add_param!' do
    let(:props) { { name: 'abc', value: 'def' } }

    subject { repository.add_param!(candidate, props[:name], props[:value]) }

    it 'adds a new param' do
      expect { subject }.to change { candidate.params.size }.by(1)
    end

    context 'when name missing' do
      let(:props) { { value: 1234 } }

      it 'throws RecordInvalid' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when param was already added' do
      it 'throws RecordInvalid' do
        repository.add_param!(candidate, 'new', props[:value])

        expect { repository.add_param!(candidate, 'new', props[:value]) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe '#add_tag!' do
    let(:props) { { name: 'abc', value: 'def' } }

    subject { repository.add_tag!(candidate, props[:name], props[:value]) }

    it 'adds a new tag' do
      expect { subject }.to change { candidate.reload.metadata.size }.by(1)
    end

    context 'when name missing' do
      let(:props) { { value: 1234 } }

      it 'throws RecordInvalid' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when tag was already added' do
      it 'throws RecordInvalid' do
        repository.add_tag!(candidate, 'new', props[:value])

        expect { repository.add_tag!(candidate, 'new', props[:value]) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'when tag starts with gitlab.' do
      it 'calls HandleCandidateGitlabMetadataService' do
        expect(Ml::ExperimentTracking::HandleCandidateGitlabMetadataService).to receive(:new).and_call_original

        repository.add_tag!(candidate, 'gitlab.CI_USER_ID', user.id)
      end
    end
  end

  describe "#add_params" do
    let(:params) do
      [{ key: 'model_class', value: 'LogisticRegression' }, { key: 'pythonEnv', value: '3.10' }]
    end

    subject { repository.add_params(candidate, params) }

    it 'adds the parameters' do
      expect { subject }.to change { candidate.reload.params.size }.by(2)
    end

    context 'if parameter misses key' do
      let(:params) do
        [{ value: 'LogisticRegression' }]
      end

      it 'does not throw and does not add' do
        expect { subject }.to raise_error(ActiveRecord::ActiveRecordError)
      end
    end

    context 'if parameter misses value' do
      let(:params) do
        [{ key: 'pythonEnv2' }]
      end

      it 'does not throw and does not add' do
        expect { subject }.to raise_error(ActiveRecord::ActiveRecordError)
      end
    end

    context 'if parameter repeated do' do
      let(:params) do
        [
          { key: 'pythonEnv0', value: '2.7' },
          { key: 'pythonEnv1', value: '3.9' },
          { key: 'pythonEnv1', value: '3.10' }
        ]
      end

      before do
        repository.add_param!(candidate, 'pythonEnv0', '0')
      end

      it 'does not throw and adds only the first of each kind' do
        expect { subject }.to change { candidate.reload.params.size }.by(1)
      end
    end
  end

  describe "#add_metrics" do
    let(:metrics) do
      [
        { key: 'mae', value: 2.5, timestamp: 1552550804 },
        { key: 'rmse', value: 2.7, timestamp: 1552550804 }
      ]
    end

    subject { repository.add_metrics(candidate, metrics) }

    it 'adds the metrics' do
      expect { subject }.to change { candidate.reload.metrics.size }.by(2)
    end

    context 'when metrics have repeated keys' do
      let(:metrics) do
        [
          { key: 'mae', value: 2.5, timestamp: 1552550804 },
          { key: 'rmse', value: 2.7, timestamp: 1552550804 },
          { key: 'mae', value: 2.7, timestamp: 1552550805 }
        ]
      end

      it 'adds all of them' do
        expect { subject }.to change { candidate.reload.metrics.size }.by(3)
      end
    end
  end

  describe "#add_tags" do
    let(:tags) do
      [{ key: 'gitlab.tag1', value: 'hello' }, { key: 'gitlab.tag2', value: 'world' }]
    end

    subject { repository.add_tags(candidate, tags) }

    it 'adds the tags' do
      expect { subject }.to change { candidate.reload.metadata.size }.by(2)
    end

    context 'if tags misses key' do
      let(:tags) { [{ value: 'hello' }] }

      it 'does throw and does not add' do
        expect { subject }.to raise_error(ActiveRecord::ActiveRecordError)
      end
    end

    context 'if tag misses value' do
      let(:tags) { [{ key: 'gitlab.tag1' }] }

      it 'does throw and does not add' do
        expect { subject }.to raise_error(ActiveRecord::ActiveRecordError)
      end
    end

    context 'if tag repeated' do
      let(:params) do
        [
          { key: 'gitlab.tag1', value: 'hello' },
          { key: 'gitlab.tag2', value: 'world' },
          { key: 'gitlab.tag1', value: 'gitlab' }
        ]
      end

      before do
        repository.add_tag!(candidate, 'gitlab.tag2', '0')
      end

      it 'does not throw and adds only the first of each kind' do
        expect { subject }.to change { candidate.reload.metadata.size }.by(1)
      end
    end

    context 'when tags is nil' do
      let(:tags) { nil }

      it 'does not handle gitlab tags' do
        expect(repository).not_to receive(:handle_gitlab_tags)

        subject
      end
    end
  end
end
