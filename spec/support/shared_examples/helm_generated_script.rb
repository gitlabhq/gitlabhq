shared_examples 'helm commands' do
  describe '#generate_script' do
    let(:helm_setup) do
      <<~EOS
         set -eo pipefail
         ALPINE_VERSION=$(cat /etc/alpine-release | cut -d '.' -f 1,2)
         echo http://mirror.clarkson.edu/alpine/v$ALPINE_VERSION/main >> /etc/apk/repositories
         echo http://mirror1.hs-esslingen.de/pub/Mirrors/alpine/v$ALPINE_VERSION/main >> /etc/apk/repositories
         apk add -U wget ca-certificates openssl git >/dev/null
         wget -q -O - https://kubernetes-helm.storage.googleapis.com/helm-v2.7.2-linux-amd64.tar.gz | tar zxC /tmp >/dev/null
         mv /tmp/linux-amd64/helm /usr/bin/

         wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
         wget -q https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.28-r0/glibc-2.28-r0.apk
         apk add glibc-2.28-r0.apk > /dev/null
         rm glibc-2.28-r0.apk
         wget -q https://storage.googleapis.com/kubernetes-release/release/v1.11.0/bin/linux/amd64/kubectl
         chmod +x kubectl
         mv kubectl /usr/bin/
      EOS
    end

    it 'should return appropriate command' do
      expect(subject.generate_script).to eq(helm_setup + commands)
    end
  end
end
