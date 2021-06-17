# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Changelog::Config do
  let(:project) { build_stubbed(:project) }

  describe '.from_git' do
    it 'retrieves the configuration from Git' do
      allow(project.repository)
        .to receive(:changelog_config)
        .and_return("---\ndate_format: '%Y'")

      expect(described_class)
        .to receive(:from_hash)
        .with(project, 'date_format' => '%Y')

      described_class.from_git(project)
    end

    it 'returns the default configuration when no YAML file exists in Git' do
      allow(project.repository)
        .to receive(:changelog_config)
        .and_return(nil)

      expect(described_class)
        .to receive(:new)
        .with(project)

      described_class.from_git(project)
    end
  end

  describe '.from_hash' do
    it 'sets the configuration according to a Hash' do
      config = described_class.from_hash(
        project,
        'date_format' => 'foo',
        'template' => 'bar',
        'categories' => { 'foo' => 'bar' },
        'tag_regex' => 'foo'
      )

      expect(config.date_format).to eq('foo')
      expect(config.template)
        .to be_instance_of(Gitlab::TemplateParser::AST::Expressions)

      expect(config.categories).to eq({ 'foo' => 'bar' })
      expect(config.tag_regex).to eq('foo')
    end

    it 'raises Error when the categories are not a Hash' do
      expect { described_class.from_hash(project, 'categories' => 10) }
        .to raise_error(Gitlab::Changelog::Error)
    end

    it 'raises a Gitlab::Changelog::Error when the template is invalid' do
      invalid_template = <<~TPL
        {% each {{foo}} %}
        {% end %}
      TPL

      expect { described_class.from_hash(project, 'template' => invalid_template) }
        .to raise_error(Gitlab::Changelog::Error)
    end
  end

  describe '#contributor?' do
    it 'returns true if a user is a contributor' do
      user = build_stubbed(:author)

      allow(project.team).to receive(:contributor?).with(user).and_return(true)

      expect(described_class.new(project).contributor?(user)).to eq(true)
    end

    it "returns true if a user isn't a contributor" do
      user = build_stubbed(:author)

      allow(project.team).to receive(:contributor?).with(user).and_return(false)

      expect(described_class.new(project).contributor?(user)).to eq(false)
    end
  end

  describe '#category' do
    it 'returns the name of a category' do
      config = described_class.new(project)

      config.categories['foo'] = 'Foo'

      expect(config.category('foo')).to eq('Foo')
    end

    it 'returns the raw category name when no alternative name is configured' do
      config = described_class.new(project)

      expect(config.category('bla')).to eq('bla')
    end
  end

  describe '#format_date' do
    it 'formats a date according to the configured date format' do
      config = described_class.new(project)
      time = Time.utc(2021, 1, 5)

      expect(config.format_date(time)).to eq('2021-01-05')
    end
  end
end
