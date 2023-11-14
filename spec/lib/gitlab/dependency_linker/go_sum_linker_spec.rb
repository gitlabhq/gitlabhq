# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DependencyLinker::GoSumLinker do
  let(:file_name) { 'go.sum' }
  let(:file_content) do
    <<-CONTENT.strip_heredoc
      github.com/davecgh/go-spew v1.1.0 h1:ZDRjVQ15GmhC3fiQ8ni8+OwkZQO4DARzQgrnXU1Liz8=
      github.com/davecgh/go-spew v1.1.0/go.mod h1:J7Y8YcW2NihsgmVo/mv3lAwl/skON4iLHjSsI+c5H38=
      github.com/pmezard/go-difflib v1.0.0 h1:4DBwDE0NGyQoBHbLQYPwSUPoCMWR5BEzIk/f1lZbAQM=
      github.com/pmezard/go-difflib v1.0.0/go.mod h1:iKH77koFhYxTK1pcRnkKkqfTogsbg7gZNVY4sRDYZ/4=
      github.com/stretchr/objx v0.1.0 h1:4G4v2dO3VZwixGIRoQ5Lfboy6nUhCyYzaqnIAPPhYs4=
      github.com/stretchr/objx v0.1.0/go.mod h1:HFkY916IF+rwdDfMAkV7OtwuqBVzrE8GR6GFx+wExME=
      github.com/stretchr/testify v1.3.0 h1:TivCn/peBQ7UY8ooIcPgZFpTNSz0Q2U6UrFlUfqbe0Q=
      github.com/stretchr/testify v1.3.0/go.mod h1:M5WIy9Dh21IEIfnGCwXGc5bZfKNJtfHm1UVUgZn+9EI=
      gitlab.com/go-utils/io v0.0.0-20190408212915-156add3f8f97 h1:9EKx8vX3kJzyj977yiWB8iIOXHyvbg8SmfOScw7OcN0=
      gitlab.com/go-utils/io v0.0.0-20190408212915-156add3f8f97/go.mod h1:cF4ez5kIKPWU1BB1Z4qgu6dQkT3pvknXff8PSlGaNo8=
      golang.org/x/xerrors v0.0.0-20190717185122-a985d3407aa7 h1:9zdDQZ7Thm29KFXgAX/+yaf3eVbP7djjWp/dXAppNCc=
      golang.org/x/xerrors v0.0.0-20190717185122-a985d3407aa7/go.mod h1:I/5z698sn9Ka8TeJc9MKroUUfqBBauWjQqLJ2OPfmY0=
    CONTENT
  end

  describe '.support?' do
    it 'supports go.sum' do
      expect(described_class.support?('go.sum')).to be_truthy
    end

    it 'does not support other files' do
      expect(described_class.support?('go.sum.example')).to be_falsey
    end
  end

  describe '#link' do
    subject { Gitlab::Highlight.highlight(file_name, file_content) }

    def link(name, url)
      %(<a href="#{url}" rel="nofollow noreferrer noopener" target="_blank">#{name}</a>)
    end

    it 'links modules' do
      expect(subject).to include(link('github.com/davecgh/go-spew', 'https://pkg.go.dev/github.com/davecgh/go-spew@v1.1.0'))
      expect(subject).to include(link('github.com/pmezard/go-difflib', 'https://pkg.go.dev/github.com/pmezard/go-difflib@v1.0.0'))
      expect(subject).to include(link('github.com/stretchr/objx', 'https://pkg.go.dev/github.com/stretchr/objx@v0.1.0'))
      expect(subject).to include(link('github.com/stretchr/testify', 'https://pkg.go.dev/github.com/stretchr/testify@v1.3.0'))
      expect(subject).to include(link('gitlab.com/go-utils/io', 'https://pkg.go.dev/gitlab.com/go-utils/io@v0.0.0-20190408212915-156add3f8f97'))
      expect(subject).to include(link('golang.org/x/xerrors', 'https://pkg.go.dev/golang.org/x/xerrors@v0.0.0-20190717185122-a985d3407aa7'))
    end

    it 'links checksums' do
      expect(subject).to include(link('ZDRjVQ15GmhC3fiQ8ni8+OwkZQO4DARzQgrnXU1Liz8=', 'https://sum.golang.org/lookup/github.com/davecgh/go-spew@v1.1.0'))
      expect(subject).to include(link('J7Y8YcW2NihsgmVo/mv3lAwl/skON4iLHjSsI+c5H38=', 'https://sum.golang.org/lookup/github.com/davecgh/go-spew@v1.1.0'))
      expect(subject).to include(link('4DBwDE0NGyQoBHbLQYPwSUPoCMWR5BEzIk/f1lZbAQM=', 'https://sum.golang.org/lookup/github.com/pmezard/go-difflib@v1.0.0'))
      expect(subject).to include(link('iKH77koFhYxTK1pcRnkKkqfTogsbg7gZNVY4sRDYZ/4=', 'https://sum.golang.org/lookup/github.com/pmezard/go-difflib@v1.0.0'))
      expect(subject).to include(link('4G4v2dO3VZwixGIRoQ5Lfboy6nUhCyYzaqnIAPPhYs4=', 'https://sum.golang.org/lookup/github.com/stretchr/objx@v0.1.0'))
      expect(subject).to include(link('HFkY916IF+rwdDfMAkV7OtwuqBVzrE8GR6GFx+wExME=', 'https://sum.golang.org/lookup/github.com/stretchr/objx@v0.1.0'))
      expect(subject).to include(link('TivCn/peBQ7UY8ooIcPgZFpTNSz0Q2U6UrFlUfqbe0Q=', 'https://sum.golang.org/lookup/github.com/stretchr/testify@v1.3.0'))
      expect(subject).to include(link('M5WIy9Dh21IEIfnGCwXGc5bZfKNJtfHm1UVUgZn+9EI=', 'https://sum.golang.org/lookup/github.com/stretchr/testify@v1.3.0'))
      expect(subject).to include(link('9EKx8vX3kJzyj977yiWB8iIOXHyvbg8SmfOScw7OcN0=', 'https://sum.golang.org/lookup/gitlab.com/go-utils/io@v0.0.0-20190408212915-156add3f8f97'))
      expect(subject).to include(link('cF4ez5kIKPWU1BB1Z4qgu6dQkT3pvknXff8PSlGaNo8=', 'https://sum.golang.org/lookup/gitlab.com/go-utils/io@v0.0.0-20190408212915-156add3f8f97'))
      expect(subject).to include(link('9zdDQZ7Thm29KFXgAX/+yaf3eVbP7djjWp/dXAppNCc=', 'https://sum.golang.org/lookup/golang.org/x/xerrors@v0.0.0-20190717185122-a985d3407aa7'))
      expect(subject).to include(link('I/5z698sn9Ka8TeJc9MKroUUfqBBauWjQqLJ2OPfmY0=', 'https://sum.golang.org/lookup/golang.org/x/xerrors@v0.0.0-20190717185122-a985d3407aa7'))
    end
  end
end
