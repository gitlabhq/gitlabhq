require 'spec_helper'

describe Namespace do
  let!(:namespace) { create(:namespace) }

  it { should have_many :projects }
  it { should validate_presence_of :name }
  it { should validate_uniqueness_of(:name) }
  it { should validate_presence_of :code }
  it { should validate_uniqueness_of(:code) }
  it { should validate_presence_of :owner }
end
