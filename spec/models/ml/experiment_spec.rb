# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::Experiment do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:candidates) }
  end

  describe '#by_project_id_and_iid?' do
    let(:exp) { create(:ml_experiments) }
    let(:iid) { exp.iid }

    subject { described_class.by_project_id_and_iid(exp.project_id, iid) }

    context 'if exists' do
      it { is_expected.to eq(exp) }
    end

    context 'if does not exist' do
      let(:iid) { non_existing_record_id }

      it { is_expected.to be(nil) }
    end
  end

  describe '#by_project_id_and_name?' do
    let(:exp) { create(:ml_experiments) }
    let(:exp_name) { exp.name }

    subject { described_class.by_project_id_and_name(exp.project_id, exp_name) }

    context 'if exists' do
      it { is_expected.to eq(exp) }
    end

    context 'if does not exist' do
      let(:exp_name) { 'hello' }

      it { is_expected.to be_nil }
    end
  end

  describe '#has_record?' do
    let(:exp) { create(:ml_experiments) }
    let(:exp_name) { exp.name }

    subject { described_class.has_record?(exp.project_id, exp_name) }

    context 'if exists' do
      it { is_expected.to be_truthy }
    end

    context 'if does not exist' do
      let(:exp_name) { 'hello' }

      it { is_expected.to be_falsey }
    end
  end
end
