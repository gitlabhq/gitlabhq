require 'spec_helper'

describe Gitlab::ServiceDoc do

  describe 'load' do
    context "without doc folder" do
      before do
        Gitlab::ServiceDoc.send(:remove_const, 'DOC_DIR')
        Gitlab::ServiceDoc::DOC_DIR = "imaginary_dir"
      end
      it { expect{ Gitlab::ServiceDoc.load }.to_not raise_error }
      it { Gitlab::ServiceDoc.instance_variable_get(:@docs).should be_empty }
    end

    context "without doc files" do
      before do
        Dir.stub(:foreach).and_return([])
      end
      it { expect{ Gitlab::ServiceDoc.load }.to_not raise_error }
      it { Gitlab::ServiceDoc.instance_variable_get(:@docs).should be_empty }
    end

    context "with doc files" do
      before do
        Gitlab::ServiceDoc.send(:remove_const, 'DOC_DIR')
        Gitlab::ServiceDoc::DOC_DIR = Rails.root.join("spec","fixtures","doc","services")
        Gitlab::ServiceDoc.load
      end
      it { Gitlab::ServiceDoc.instance_variable_get(:@docs).should_not be_empty }
      it { Gitlab::ServiceDoc.get("example").should  == "This is a sample documentation file" }
    end
  end

end
