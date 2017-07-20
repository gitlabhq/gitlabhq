require 'rails_helper'

describe ProjectMirrorData, type: :model do
  include Gitlab::CurrentSettings

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'modules' do
    it { is_expected.to include_module(Gitlab::CurrentSettings) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end

  describe 'when create' do
    it 'sets next execution timestamp to now' do
      project = create(:empty_project)

      Timecop.freeze(Time.now) do
        project.create_mirror_data

        expect(project.mirror_data.next_execution_timestamp).to eq(Time.now)
      end
    end
  end

  describe '#reset_retry_count!' do
    let(:mirror_data) { create(:project, :mirror, :import_finished).mirror_data }

    it 'resets retry_count to 0' do
      mirror_data.retry_count = 3

      expect { mirror_data.reset_retry_count! }.to change { mirror_data.retry_count }.from(3).to(0)
    end
  end

  describe '#increment_retry_count!' do
    let(:mirror_data) { create(:project, :mirror, :import_finished).mirror_data }

    it 'increments retry_count' do
      expect { mirror_data.increment_retry_count! }.to change { mirror_data.retry_count }.from(0).to(1)
    end
  end

  describe '#set_next_execution_timestamp!' do
    let(:mirror_data) { create(:project, :mirror, :import_finished).mirror_data }
    let!(:timestamp) { Time.now }
    let!(:jitter) { 2.seconds }
    let(:interval) { 2.minutes }

    before do
      allow_any_instance_of(ProjectMirrorData).to receive(:rand).and_return(jitter)
    end

    context 'when base delay is lower than mirror_max_delay' do
      before do
        mirror_data.last_update_started_at = timestamp - 1.minute
      end

      context 'when retry count is 0' do
        it 'applies transition successfully' do
          expect do
            mirror_data.set_next_execution_timestamp!
          end.to change { mirror_data.next_execution_timestamp }.to be_within(interval).of(timestamp + 26.minutes)
        end
      end

      context 'when incrementing retry count' do
        it 'applies transition successfully' do
          mirror_data.retry_count = 2
          mirror_data.increment_retry_count!

          expect do
            mirror_data.set_next_execution_timestamp!
          end.to change { mirror_data.next_execution_timestamp }.to be_within(interval).of(timestamp + 79.minutes)
        end
      end
    end

    context 'when boundaries are surpassed' do
      let!(:mirror_jitter) { 30.seconds }

      context 'when base delay is lower than mirror min_delay' do
        before do
          allow_any_instance_of(Gitlab::Mirror).to receive(:rand).and_return(mirror_jitter)
          mirror_data.last_update_started_at = timestamp - 1.second
        end

        context 'when resetting retry count' do
          it 'applies transition successfully' do
            expect do
              mirror_data.set_next_execution_timestamp!
            end.to change { mirror_data.next_execution_timestamp }.to be_within(interval).of(timestamp + 15.minutes)
          end
        end

        context 'when incrementing retry count' do
          it 'applies transition successfully' do
            mirror_data.retry_count = 2
            mirror_data.increment_retry_count!

            expect do
              mirror_data.set_next_execution_timestamp!
            end.to change { mirror_data.next_execution_timestamp }.to be_within(interval).of(timestamp + 15.minutes)
          end
        end
      end

      context 'when base delay is higher than mirror_max_delay' do
        let(:max_timestamp) { timestamp + current_application_settings.mirror_max_delay.minutes }

        before do
          allow_any_instance_of(Gitlab::Mirror).to receive(:rand).and_return(mirror_jitter)
          mirror_data.last_update_started_at = timestamp - 1.hour
        end

        context 'when resetting retry count' do
          it 'applies transition successfully' do
            expect do
              mirror_data.set_next_execution_timestamp!
            end.to change { mirror_data.next_execution_timestamp }.to be_within(interval).of(max_timestamp + mirror_jitter)
          end
        end

        context 'when incrementing retry count' do
          it 'applies transition successfully' do
            mirror_data.retry_count = 2
            mirror_data.increment_retry_count!

            expect do
              mirror_data.set_next_execution_timestamp!
            end.to change { mirror_data.next_execution_timestamp }.to be_within(interval).of(max_timestamp + mirror_jitter)
          end
        end
      end
    end
  end
end
