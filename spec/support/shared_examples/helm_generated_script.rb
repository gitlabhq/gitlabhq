shared_examples 'helm commands' do
  describe '#generate_script' do
    let(:helm_setup) do
      <<~EOS
         set -eo pipefail
         ALPINE_VERSION=$(cat /etc/alpine-release | cut -d '.' -f 1,2)
         echo http://mirror.clarkson.edu/alpine/v$ALPINE_VERSION/main >> /etc/apk/repositories
         echo http://mirror1.hs-esslingen.de/pub/Mirrors/alpine/v$ALPINE_VERSION/main >> /etc/apk/repositories
         apk add -U ca-certificates openssl >/dev/null
         wget -q -O - https://kubernetes-helm.storage.googleapis.com/helm-v2.7.0-linux-amd64.tar.gz | tar zxC /tmp >/dev/null
         mv /tmp/linux-amd64/helm /usr/bin/
      EOS
    end

    it 'should return appropriate command' do
      expect(subject.generate_script).to eq(helm_setup + commands)
    end
  end
end
