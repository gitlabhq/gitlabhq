# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace::RootStorageStatistics, type: :model do
  it { is_expected.to belong_to :namespace }
  it { is_expected.to have_one(:route).through(:namespace) }

  it { is_expected.to delegate_method(:all_projects).to(:namespace) }
end
