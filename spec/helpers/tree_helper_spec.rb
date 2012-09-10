require 'spec_helper'

describe TreeHelper do
  describe '#markup?' do
    %w(mdown md markdown textile rdoc org creole mediawiki rst asciidoc pod).each do |type|
      it "returns true for #{type} files" do
        markup?("README.#{type}").should be_true
      end
    end

    it "returns false when given a non-markup filename" do
      markup?('README.rb').should_not be_true
    end
  end
end
