# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Approval do
  context 'presence validation' do
    it { is_expected.to validate_presence_of(:merge_request_id) }
    it { is_expected.to validate_presence_of(:user_id) }
  end

  context 'uniqueness validation' do
    let!(:existing_record) { create(:approval) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to([:merge_request_id]) }
  end
end
