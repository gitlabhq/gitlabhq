# frozen_string_literal: true

require 'spec_helper'

shared_examples_for 'UpdateProjectStatistics' do
  let(:project) { subject.project }
  let(:project_statistics_name) { described_class.project_statistics_name }
  let(:statistic_attribute) { described_class.statistic_attribute }

  def reload_stat
    project.statistics.reload.send(project_statistics_name).to_i
  end

  def read_attribute
    subject.read_attribute(statistic_attribute).to_i
  end

  it { is_expected.to be_new_record }

  context 'when creating' do
    it 'updates the project statistics' do
      delta = read_attribute

      expect { subject.save! }
        .to change { reload_stat }
        .by(delta)
    end
  end

  context 'when updating' do
    before do
      subject.save!
    end

    it 'updates project statistics' do
      delta = 42

      expect(ProjectStatistics)
        .to receive(:increment_statistic)
        .and_call_original

      subject.write_attribute(statistic_attribute, read_attribute + delta)

      expect { subject.save! }
        .to change { reload_stat }
        .by(delta)
    end
  end

  context 'when destroying' do
    before do
      subject.save!
    end

    it 'updates the project statistics' do
      delta = -read_attribute

      expect(ProjectStatistics)
        .to receive(:increment_statistic)
        .and_call_original

      expect { subject.destroy }
        .to change { reload_stat }
        .by(delta)
    end

    context 'when it is destroyed from the project level' do
      it 'does not update the project statistics' do
        expect(ProjectStatistics)
          .not_to receive(:increment_statistic)

        project.update(pending_delete: true)
        project.destroy!
      end
    end
  end
end
