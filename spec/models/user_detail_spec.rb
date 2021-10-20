# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserDetail do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to define_enum_for(:registration_objective).with_values([:basics, :move_repository, :code_storage, :exploring, :ci, :other, :joining_team]).with_suffix }

  describe 'validations' do
    describe '#job_title' do
      it { is_expected.not_to validate_presence_of(:job_title) }
      it { is_expected.to validate_length_of(:job_title).is_at_most(200) }
    end

    describe '#pronouns' do
      it { is_expected.not_to validate_presence_of(:pronouns) }
      it { is_expected.to validate_length_of(:pronouns).is_at_most(50) }
    end

    describe '#pronunciation' do
      it { is_expected.not_to validate_presence_of(:pronunciation) }
      it { is_expected.to validate_length_of(:pronunciation).is_at_most(255) }
    end

    describe '#bio' do
      it { is_expected.to validate_length_of(:bio).is_at_most(255) }
    end
  end
end
