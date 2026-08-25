# frozen_string_literal: true

require 'spec_helper'
require './keeps/helpers/rubocop_todo_generator'

RSpec.describe Keeps::Helpers::RubocopTodoGenerator, feature_category: :tooling do
  let(:rake_task) { instance_double(Rake::Task) }

  subject(:generator) { described_class.new }

  describe '#generate' do
    it 'loads the application tasks and invokes the rubocop todo generate task' do
      allow(Rake::Task).to receive(:[]).with('rubocop:todo:generate').and_return(rake_task)

      expect(Gitlab::Application).to receive(:load_tasks)
      expect(rake_task).to receive(:invoke)

      generator.generate
    end
  end
end
