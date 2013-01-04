describe Repository do
  describe "Respond to" do
    it { should respond_to(:repo) }
    it { should respond_to(:tree) }
    it { should respond_to(:root_ref) }
    it { should respond_to(:tags) }
    it { should respond_to(:commit) }
    it { should respond_to(:commits) }
    it { should respond_to(:commits_between) }
    it { should respond_to(:commits_with_refs) }
    it { should respond_to(:commits_since) }
    it { should respond_to(:commits_between) }
  end
end
