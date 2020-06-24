# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserDetail do
  it { is_expected.to belong_to(:user) }

  describe 'validations' do
    describe 'job_title' do
      it { is_expected.not_to validate_presence_of(:job_title) }
      it { is_expected.to validate_length_of(:job_title).is_at_most(200) }
    end
  end
end
