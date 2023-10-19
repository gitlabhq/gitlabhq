# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DependencyLinker::GoModLinker do
  let(:file_name) { 'go.mod' }
  let(:file_content) do
    <<-CONTENT.strip_heredoc
      module gitlab.com/gitlab-org/gitlab-workhorse

      go 1.12

      require (
        github.com/BurntSushi/toml v0.3.1
        github.com/FZambia/sentinel v1.0.0
        github.com/alecthomas/chroma v0.7.3
        github.com/dgrijalva/jwt-go v3.2.0+incompatible
        github.com/getsentry/raven-go v0.1.2
        github.com/golang/gddo v0.0.0-20190419222130-af0f2af80721
        github.com/golang/protobuf v1.3.2
        github.com/gomodule/redigo v2.0.0+incompatible
        github.com/gorilla/websocket v1.4.0
        github.com/grpc-ecosystem/go-grpc-middleware v1.0.0
        github.com/grpc-ecosystem/go-grpc-prometheus v1.2.0
        github.com/jfbus/httprs v0.0.0-20190827093123-b0af8319bb15
        github.com/jpillora/backoff v0.0.0-20170918002102-8eab2debe79d
        github.com/prometheus/client_golang v1.0.0
        github.com/rafaeljusto/redigomock v0.0.0-20190202135759-257e089e14a1
        github.com/sebest/xff v0.0.0-20160910043805-6c115e0ffa35
        github.com/sirupsen/logrus v1.3.0
        github.com/stretchr/testify v1.5.1
        gitlab.com/gitlab-org/gitaly v1.74.0
        gitlab.com/gitlab-org/labkit v0.0.0-20200520155818-96e583c57891
        golang.org/x/lint v0.0.0-20191125180803-fdd1cda4f05f
        golang.org/x/net v0.0.0-20200114155413-6afb5195e5aa
        golang.org/x/tools v0.0.0-20200117161641-43d50277825c
        google.golang.org/grpc v1.24.0
        gopkg.in/yaml.v2 v2.2.8 // indirect
        honnef.co/go/tools v0.0.1-2019.2.3
      )
    CONTENT
  end

  describe '.support?' do
    it 'supports go.mod' do
      expect(described_class.support?('go.mod')).to be_truthy
    end

    it 'does not support other files' do
      expect(described_class.support?('go.mod.example')).to be_falsey
    end
  end

  describe '#link' do
    subject { Gitlab::Highlight.highlight(file_name, file_content) }

    def link(name, url)
      %(<a href="#{url}" rel="nofollow noreferrer noopener" target="_blank">#{name}</a>)
    end

    it 'links the module name' do
      expect(subject).to include(link('gitlab.com/gitlab-org/gitlab-workhorse', 'https://pkg.go.dev/gitlab.com/gitlab-org/gitlab-workhorse'))
    end

    it 'links dependencies' do
      expect(subject).to include(link('github.com/BurntSushi/toml', 'https://pkg.go.dev/github.com/BurntSushi/toml@v0.3.1'))
      expect(subject).to include(link('github.com/FZambia/sentinel', 'https://pkg.go.dev/github.com/FZambia/sentinel@v1.0.0'))
      expect(subject).to include(link('github.com/alecthomas/chroma', 'https://pkg.go.dev/github.com/alecthomas/chroma@v0.7.3'))
      expect(subject).to include(link('github.com/dgrijalva/jwt-go', 'https://pkg.go.dev/github.com/dgrijalva/jwt-go@v3.2.0+incompatible'))
      expect(subject).to include(link('github.com/getsentry/raven-go', 'https://pkg.go.dev/github.com/getsentry/raven-go@v0.1.2'))
      expect(subject).to include(link('github.com/golang/gddo', 'https://pkg.go.dev/github.com/golang/gddo@v0.0.0-20190419222130-af0f2af80721'))
      expect(subject).to include(link('github.com/golang/protobuf', 'https://pkg.go.dev/github.com/golang/protobuf@v1.3.2'))
      expect(subject).to include(link('github.com/gomodule/redigo', 'https://pkg.go.dev/github.com/gomodule/redigo@v2.0.0+incompatible'))
      expect(subject).to include(link('github.com/gorilla/websocket', 'https://pkg.go.dev/github.com/gorilla/websocket@v1.4.0'))
      expect(subject).to include(link('github.com/grpc-ecosystem/go-grpc-middleware', 'https://pkg.go.dev/github.com/grpc-ecosystem/go-grpc-middleware@v1.0.0'))
      expect(subject).to include(link('github.com/grpc-ecosystem/go-grpc-prometheus', 'https://pkg.go.dev/github.com/grpc-ecosystem/go-grpc-prometheus@v1.2.0'))
      expect(subject).to include(link('github.com/jfbus/httprs', 'https://pkg.go.dev/github.com/jfbus/httprs@v0.0.0-20190827093123-b0af8319bb15'))
      expect(subject).to include(link('github.com/jpillora/backoff', 'https://pkg.go.dev/github.com/jpillora/backoff@v0.0.0-20170918002102-8eab2debe79d'))
      expect(subject).to include(link('github.com/prometheus/client_golang', 'https://pkg.go.dev/github.com/prometheus/client_golang@v1.0.0'))
      expect(subject).to include(link('github.com/rafaeljusto/redigomock', 'https://pkg.go.dev/github.com/rafaeljusto/redigomock@v0.0.0-20190202135759-257e089e14a1'))
      expect(subject).to include(link('github.com/sebest/xff', 'https://pkg.go.dev/github.com/sebest/xff@v0.0.0-20160910043805-6c115e0ffa35'))
      expect(subject).to include(link('github.com/sirupsen/logrus', 'https://pkg.go.dev/github.com/sirupsen/logrus@v1.3.0'))
      expect(subject).to include(link('github.com/stretchr/testify', 'https://pkg.go.dev/github.com/stretchr/testify@v1.5.1'))
      expect(subject).to include(link('gitlab.com/gitlab-org/gitaly', 'https://pkg.go.dev/gitlab.com/gitlab-org/gitaly@v1.74.0'))
      expect(subject).to include(link('gitlab.com/gitlab-org/labkit', 'https://pkg.go.dev/gitlab.com/gitlab-org/labkit@v0.0.0-20200520155818-96e583c57891'))
      expect(subject).to include(link('golang.org/x/lint', 'https://pkg.go.dev/golang.org/x/lint@v0.0.0-20191125180803-fdd1cda4f05f'))
      expect(subject).to include(link('golang.org/x/net', 'https://pkg.go.dev/golang.org/x/net@v0.0.0-20200114155413-6afb5195e5aa'))
      expect(subject).to include(link('golang.org/x/tools', 'https://pkg.go.dev/golang.org/x/tools@v0.0.0-20200117161641-43d50277825c'))
      expect(subject).to include(link('google.golang.org/grpc', 'https://pkg.go.dev/google.golang.org/grpc@v1.24.0'))
      expect(subject).to include(link('gopkg.in/yaml.v2', 'https://pkg.go.dev/gopkg.in/yaml.v2@v2.2.8'))
      expect(subject).to include(link('honnef.co/go/tools', 'https://pkg.go.dev/honnef.co/go/tools@v0.0.1-2019.2.3'))
    end
  end
end
