# frozen_string_literal: true

# Shared examples that test requests against URLs with escaped elements
#
RSpec.shared_examples "URLs containing escaped elements return expected status" do
  using RSpec::Parameterized::TableSyntax

  where(:url, :result_status) do
    "https://user:0a%23@test.example.com/project.git"                               | :success
    "https://git.example.com:1%2F%2F@source.developers.google.com/project.git"      | :success
    CGI.escape("git://localhost:1234/some-path?some-query=some-val\#@example.com/") | :error
    CGI.escape(CGI.escape("https://user:0a%23@test.example.com/project.git"))       | :error
  end

  with_them do
    it "returns expected status" do
      expect(result[:status]).to eq(result_status)
    end
  end
end
