# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DataTransfer, feature_category: :source_code_management do
  let_it_be(:project) { create(:project) }

  it { expect(subject).to be_valid }

  # tests DataTransferCounterAttribute with the appropiate attributes
  it_behaves_like CounterAttribute,
    %i[repository_egress artifacts_egress packages_egress registry_egress] do
    let(:model) { create(:project_data_transfer, project: project) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:namespace) }
  end

  describe 'scopes' do
    let(:dates) { %w[2023-01-01 2023-02-01 2023-03-01] }

    before do
      dates.each { |date| create(:project_data_transfer, project: project, date: date) }
    end

    describe '.current_month' do
      subject { described_class.current_month }

      it 'returns data transfer for the current month' do
        travel_to(Time.utc(2022, 5, 2)) do
          _past_month = create(:project_data_transfer, project: project, date: '2022-04-01')
          current_month = create(:project_data_transfer, project: project, date: '2022-05-01')

          is_expected.to match_array([current_month])
        end
      end
    end

    describe '.with_project_between_dates' do
      subject do
        described_class.with_project_between_dates(project, Date.new(2023, 2, 1), Date.new(2023, 3, 1))
      end

      it 'returns the correct number of results' do
        expect(subject.size).to eq(2)
      end
    end

    describe '.with_namespace_between_dates' do
      subject do
        described_class.with_namespace_between_dates(project.namespace, Date.new(2023, 2, 1), Date.new(2023, 3, 1))
      end

      it 'returns the correct number of results' do
        expect(subject.select(:namespace_id).to_a.size).to eq(2)
      end
    end
  end

  describe '.beginning_of_month' do
    subject { described_class.beginning_of_month(time) }

    let(:time) { Time.utc(2022, 5, 2) }

    it { is_expected.to eq(Time.utc(2022, 5, 1)) }
  end

  describe 'unique index' do
    before do
      create(:project_data_transfer, project: project, date: '2022-05-01')
    end

    it 'raises unique index violation' do
      expect { create(:project_data_transfer, project: project, namespace: project.root_namespace, date: '2022-05-01') }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    context 'when project was moved from one namespace to another' do
      it 'creates a new record' do
        expect { create(:project_data_transfer, project: project, namespace: create(:namespace), date: '2022-05-01') }
          .to change { described_class.count }.by(1)
      end
    end

    context 'when a different project is created' do
      it 'creates a new record' do
        expect { create(:project_data_transfer, project: build(:project), date: '2022-05-01') }
          .to change { described_class.count }.by(1)
      end
    end
  end
end
