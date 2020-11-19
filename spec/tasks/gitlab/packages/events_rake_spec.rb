# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:packages:events namespace rake task' do
  before :all do
    Rake.application.rake_require 'tasks/gitlab/packages/events'
  end

  describe 'generate' do
    subject do
      file = double('file')
      yml_file = nil

      allow(file).to receive(:<<) { |contents| yml_file = contents }
      allow(File).to receive(:open).and_yield(file)

      run_rake_task('gitlab:packages:events:generate')

      YAML.safe_load(yml_file)
    end

    it 'excludes guest events' do
      expect(subject.find { |event| event['name'].include?("guest") }).to be_nil
    end

    ::Packages::Event::EVENT_SCOPES.keys.each do |event_scope|
      it "includes includes `#{event_scope}` scope" do
        expect(subject.find { |event| event['name'].include?(event_scope) }).not_to be_nil
      end
    end

    it 'excludes some event types' do
      expect(subject.find { |event| event['name'].include?("search_package") }).to be_nil
      expect(subject.find { |event| event['name'].include?("list_package") }).to be_nil
    end
  end
end
