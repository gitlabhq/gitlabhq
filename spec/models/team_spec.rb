describe Team do
  describe "Respond to" do
    it { should respond_to(:developers) }
    it { should respond_to(:masters) }
    it { should respond_to(:reporters) }
    it { should respond_to(:guests) }
    it { should respond_to(:repository_writers) }
    it { should respond_to(:repository_masters) }
    it { should respond_to(:repository_readers) }
  end
end

