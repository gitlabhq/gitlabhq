require 'spec_helper'

describe Commit do
  let(:commit) { create(:project).commit }

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
end
