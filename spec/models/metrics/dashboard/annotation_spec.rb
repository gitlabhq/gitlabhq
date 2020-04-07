# frozen_string_literal: true

require 'spec_helper'

describe Metrics::Dashboard::Annotation do
  describe 'associations' do
    it { is_expected.to belong_to(:environment).inverse_of(:metrics_dashboard_annotations) }
    it { is_expected.to belong_to(:cluster).class_name('Clusters::Cluster').inverse_of(:metrics_dashboard_annotations) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:dashboard_path) }
    it { is_expected.to validate_presence_of(:starting_at) }
    it { is_expected.to validate_length_of(:dashboard_path).is_at_most(255) }
    it { is_expected.to validate_length_of(:panel_xid).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(255) }

    context 'orphaned annotation' do
      subject { build(:metrics_dashboard_annotation, environment: nil) }

      it { is_expected.not_to be_valid }

      it 'reports error about both missing relations' do
        subject.valid?

        expect(subject.errors.full_messages).to include(/Annotation must belong to a cluster or an environment/)
      end
    end

    context 'environments annotation' do
      subject { build(:metrics_dashboard_annotation) }

      it { is_expected.to be_valid }
    end

    context 'clusters annotation' do
      subject { build(:metrics_dashboard_annotation, :with_cluster) }

      it { is_expected.to be_valid }
    end

    context 'annotation with shared ownership' do
      subject { build(:metrics_dashboard_annotation, :with_cluster, environment: build(:environment) ) }

      it 'reports error about both shared ownership' do
        subject.valid?

        expect(subject.errors.full_messages).to include(/Annotation can't belong to both a cluster and an environment at the same time/)
      end
    end
  end
end
