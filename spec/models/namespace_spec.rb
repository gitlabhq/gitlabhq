# == Schema Information
#
# Table name: namespaces
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  path       :string(255)      not null
#  owner_id   :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string(255)
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

  it { Namespace.global_id.should == 'GLN' }

  describe :to_param do
    it { namespace.to_param.should == namespace.path }
  end

  describe :human_name do
    it { namespace.human_name.should == namespace.owner_name }
  end

  describe :search do
    before do
      @namespace = create :namespace
    end

    it { Namespace.search(@namespace.path).should == [@namespace] }
    it { Namespace.search('unknown').should == [] }
  end

  describe :move_dir do
    before do
      @namespace = create :namespace
      @namespace.stub(path_changed?: true)
    end

    it "should raise error when dirtory exists" do
      expect { @namespace.move_dir }.to raise_error("Already exists")
    end

    it "should move dir if path changed" do
      new_path = @namespace.path + "_new"
      @namespace.stub(path_was: @namespace.path)
      @namespace.stub(path: new_path)
      @namespace.move_dir.should be_true
    end
  end

  describe :rm_dir do
    it "should remove dir" do
      namespace.rm_dir.should be_true
    end
  end
end
