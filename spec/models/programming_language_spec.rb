# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProgrammingLanguage do
  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:color) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to allow_value("#000000").for(:color) }
  it { is_expected.not_to allow_value("000000").for(:color) }
  it { is_expected.not_to allow_value("#0z0000").for(:color) }
end
