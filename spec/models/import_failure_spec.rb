# frozen_string_literal: true

require 'spec_helper'

describe ImportFailure do
  describe "Associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:group) }
  end

  describe 'Validations' do
    context 'has no group' do
      before do
        allow(subject).to receive(:group).and_return(nil)
      end

      it { is_expected.to validate_presence_of(:project) }
    end

    context 'has no project' do
      before do
        allow(subject).to receive(:project).and_return(nil)
      end

      it { is_expected.to validate_presence_of(:group) }
    end
  end
end
