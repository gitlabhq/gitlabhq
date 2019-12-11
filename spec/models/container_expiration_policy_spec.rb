# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerExpirationPolicy, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }

    describe '#enabled' do
      it { is_expected.to allow_value(true).for(:enabled) }
      it { is_expected.to allow_value(false).for(:enabled) }
      it { is_expected.not_to allow_value(nil).for(:enabled) }
    end

    describe '#cadence' do
      it { is_expected.to validate_presence_of(:cadence) }

      it { is_expected.to allow_value('1d').for(:cadence) }
      it { is_expected.to allow_value('1month').for(:cadence) }
      it { is_expected.not_to allow_value('123asdf').for(:cadence) }
      it { is_expected.not_to allow_value(nil).for(:cadence) }
    end

    describe '#older_than' do
      it { is_expected.to allow_value('7d').for(:older_than) }
      it { is_expected.to allow_value('14d').for(:older_than) }
      it { is_expected.to allow_value(nil).for(:older_than) }
      it { is_expected.not_to allow_value('123asdf').for(:older_than) }
    end

    describe '#keep_n' do
      it { is_expected.to allow_value(10).for(:keep_n) }
      it { is_expected.to allow_value(nil).for(:keep_n) }
      it { is_expected.not_to allow_value('foo').for(:keep_n) }
    end
  end
end
