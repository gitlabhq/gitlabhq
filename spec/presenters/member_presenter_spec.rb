# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberPresenter, feature_category: :subgroups do
  let_it_be(:member) { build(:group_member) }
  let(:presenter) { described_class.new(member) }

  describe '#last_owner?' do
    it 'raises `NotImplementedError`' do
      expect { presenter.last_owner? }.to raise_error(NotImplementedError)
    end
  end
end
