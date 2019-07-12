shared_context :email_shared_context do
  let(:mail_key) { "59d8df8370b7e95c5a49fbf86aeb2c93" }
  let(:receiver) { Gitlab::Email::Receiver.new(email_raw) }
  let(:markdown) { "![image](uploads/image.png)" }

  def setup_attachment
    allow_any_instance_of(Gitlab::Email::AttachmentUploader).to receive(:execute).and_return(
      [
        {
          url: "uploads/image.png",
          alt: "image",
          markdown: markdown
        }
      ]
    )
  end
end

shared_examples :reply_processing_shared_examples do
  context "when the user could not be found" do
    before do
      user.destroy
    end

    it "raises a UserNotFoundError" do
      expect { receiver.execute }.to raise_error(Gitlab::Email::UserNotFoundError)
    end
  end

  context "when the user is not authorized to the project" do
    before do
      project.update_attribute(:visibility_level, Project::PRIVATE)
    end

    it "raises a ProjectNotFound" do
      expect { receiver.execute }.to raise_error(Gitlab::Email::ProjectNotFound)
    end
  end
end
