# frozen_string_literal: true

module DangerSpecHelper
  def new_fake_danger
    Class.new do
      attr_reader :git, :gitlab, :helper

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def initialize(git: nil, gitlab: nil, helper: nil)
        @git = git
        @gitlab = gitlab
        @helper = helper
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables
    end
  end
end
