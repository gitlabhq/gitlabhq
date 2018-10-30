# frozen_string_literal: true

require 'spec_helper'

describe ProjectClusterablePresenter do
  include Gitlab::Routing.url_helpers

  let(:presenter) { described_class.new(project) }
  let(:project) { create(:project) }

  describe '#can_create_cluster?' do
    let(:user) { create(:user) }

    subject { presenter.can_create_cluster? }

    before do
      allow(presenter).to receive(:current_user).and_return(user)
    end

    context 'when user can create' do
      before do
        project.add_maintainer(user)
      end

      it { is_expected.to be_truthy }
    end

    context 'when user cannot create' do
      it { is_expected.to be_falsey }
    end
  end

  describe '#index_path' do
    subject { presenter.index_path }

    it { is_expected.to eq(project_clusters_path(project)) }
  end

  describe '#new_path' do
    subject { presenter.new_path }

    it { is_expected.to eq(new_project_cluster_path(project)) }
  end

  describe '#clusterable_params' do
    subject { presenter.clusterable_params }

    it { is_expected.to eq({ project_id: project.to_param, namespace_id: project.namespace.to_param }) }
  end
end
