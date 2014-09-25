require 'spec_helper'

describe Gitlab::MarkdownHelper do
  describe '#markup?' do
    %w(textile rdoc org creole wiki
       mediawiki rst adoc asciidoc asc).each do |type|
      it "returns true for #{type} files" do
        Gitlab::MarkdownHelper.markup?("README.#{type}").should be_true
      end
    end

    it 'returns false when given a non-markup filename' do
      Gitlab::MarkdownHelper.markup?('README.rb').should_not be_true
    end
  end

  describe '#gitlab_markdown?' do
    %w(mdown md markdown).each do |type|
      it "returns true for #{type} files" do
        Gitlab::MarkdownHelper.gitlab_markdown?("README.#{type}").should be_true
      end
    end

    it 'returns false when given a non-markdown filename' do
      Gitlab::MarkdownHelper.gitlab_markdown?('README.rb').should_not be_true
    end
  end
end
