require 'spec_helper'

describe Gitlab::ProjectServiceDoc do

  describe 'load' do
    context "without doc folder" do
      before do
        Gitlab::ProjectServiceDoc.send(:remove_const, 'DOC_DIR')
        Gitlab::ProjectServiceDoc::DOC_DIR = "imaginary_dir"
      end
      it { expect{ Gitlab::ProjectServiceDoc.load }.to_not raise_error }
      it { Gitlab::ProjectServiceDoc.instance_variable_get(:@docs).should be_empty }
    end

    context "without doc files" do
      before do
        Dir.stub(:foreach).and_return([])
      end
      it { expect{ Gitlab::ProjectServiceDoc.load }.to_not raise_error }
      it { Gitlab::ProjectServiceDoc.instance_variable_get(:@docs).should be_empty }
    end

    context "with doc files" do
      before do
        Gitlab::ProjectServiceDoc.send(:remove_const, 'DOC_DIR')
        Gitlab::ProjectServiceDoc::DOC_DIR = Rails.root.join("spec","fixtures","doc","project_services")
        Gitlab::ProjectServiceDoc.load
      end
      it { Gitlab::ProjectServiceDoc.instance_variable_get(:@docs).should_not be_empty }
      it { Gitlab::ProjectServiceDoc.get("example").should  == "This is a sample documentation file" }
    end
  end

end
