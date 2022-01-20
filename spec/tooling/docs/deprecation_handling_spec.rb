# frozen_string_literal: true

require_relative '../../fast_spec_helper'
require_relative '../../../tooling/docs/deprecation_handling'
require_relative '../../support/helpers/next_instance_of'

RSpec.describe Docs::DeprecationHandling do
  include ::NextInstanceOf

  let(:type) { 'deprecation' }

  subject { described_class.new(type).render }

  before do
    allow(Rake::FileList).to receive(:new).and_return(
      ['14-10-c.yml', '14-2-b.yml', '14-2-a.yml']
    )
    # Create dummy YAML data based on file name
    allow(YAML).to receive(:load_file) do |file_name|
      {
        'name' => file_name[/[a-z]*\.yml/],
        'announcement_milestone' => file_name[/\d+-\d+/].tr('-', '.')
      }
    end
  end

  it 'sorts entries and milestones' do
    allow_next_instance_of(ERB) do |template|
      expect(template).to receive(:result_with_hash) do |arguments|
        milestones = arguments[:milestones]
        entries = arguments[:entries]

        expect(milestones).to eq(['14.2', '14.10'])
        expect(entries.map { |e| e['name'] }).to eq(['a.yml', 'b.yml', 'c.yml'])
      end
    end

    subject
  end
end
