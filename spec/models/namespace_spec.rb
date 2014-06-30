# == Schema Information
#
# Table name: namespaces
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  path        :string(255)      not null
#  owner_id    :integer
#  created_at  :datetime
#  updated_at  :datetime
#  type        :string(255)
#  description :string(255)      default(""), not null
#  avatar      :string(255)
#

require 'spec_helper'

describe Namespace do
  let!(:namespace) { create(:namespace) }

  it { should have_many :projects }
  it { should validate_presence_of :name }
  it { should validate_uniqueness_of(:name) }
  it { should validate_presence_of :path }
  it { should validate_uniqueness_of(:path) }
  it { should validate_presence_of :owner }

  describe "Mass assignment" do
    it { should allow_mass_assignment_of(:name) }
    it { should allow_mass_assignment_of(:path) }
  end

  describe "Respond to" do
    it { should respond_to(:human_name) }
    it { should respond_to(:to_param) }
  end

  it { expect(Namespace.global_id).to eq('GLN') }

  describe :to_param do
    it { expect(namespace.to_param).to eq(namespace.path) }
  end

  describe :human_name do
    it { expect(namespace.human_name).to eq(namespace.owner_name) }
  end

  describe :search do
    before do
      @namespace = create :namespace
    end

    it { expect(Namespace.search(@namespace.path)).to eq([@namespace]) }
    it { expect(Namespace.search('unknown')).to eq([]) }
  end

  describe :move_dir do
    before do
      @namespace = create :namespace
      @namespace.stub(path_changed?: true)
    end

    it "should raise error when directory exists" do
      expect { @namespace.move_dir }.to raise_error("namespace directory cannot be moved")
    end

    it "should move dir if path changed" do
      new_path = @namespace.path + "_new"
      @namespace.stub(path_was: @namespace.path)
      @namespace.stub(path: new_path)
      expect(@namespace.move_dir).to be_true
    end
  end

  describe :rm_dir do
    it "should remove dir" do
      expect(namespace.rm_dir).to be_true
    end
  end
end
