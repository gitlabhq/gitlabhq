require 'spec_helper'

describe Commit do
  let(:commit) { create(:project).repository.commit }

  describe CommitDecorator do
    let(:decorator) { CommitDecorator.new(commit) }

    describe '#title' do
      it "returns no_commit_message when safe_message is blank" do
        decorator.stub(:safe_message).and_return('')
        decorator.title.should == "--no commit message"
      end

      it "truncates a message without a newline at 70 characters" do
        message = commit.safe_message * 10

        decorator.stub(:safe_message).and_return(message)
        decorator.title.should == "#{message[0..69]}&hellip;"
      end

      it "truncates a message with a newline before 80 characters at the newline" do
        message = commit.safe_message.split(" ").first

        decorator.stub(:safe_message).and_return(message + "\n" + message)
        decorator.title.should == message
      end

      it "truncates a message with a newline after 80 characters at 70 characters" do
        message = (commit.safe_message * 10) + "\n"

        decorator.stub(:safe_message).and_return(message)
        decorator.title.should == "#{message[0..69]}&hellip;"
      end
    end
  end

  describe "delegation" do
    subject { commit }

    it { should respond_to(:message) }
    it { should respond_to(:authored_date) }
    it { should respond_to(:committed_date) }
    it { should respond_to(:parents) }
    it { should respond_to(:date) }
    it { should respond_to(:committer) }
    it { should respond_to(:author) }
    it { should respond_to(:diffs) }
    it { should respond_to(:tree) }
    it { should respond_to(:id) }
    it { should respond_to(:to_patch) }
  end
end
