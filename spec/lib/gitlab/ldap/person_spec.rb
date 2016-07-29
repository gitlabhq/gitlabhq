require "spec_helper"

describe Gitlab::LDAP::Person do

  describe "#kerberos_principal" do

    let(:entry) do
      ldif = "dn: cn=foo, dc=bar, dc=com\n"
      ldif += "sAMAccountName: #{sam_account_name}\n" if sam_account_name
      Net::LDAP::Entry.from_single_ldif_string(ldif)
    end

    subject { Gitlab::LDAP::Person.new(entry, 'ldapmain') }

    context "when sAMAccountName is not defined (non-AD LDAP server)" do

      let(:sam_account_name) { nil }

      it "returns nil" do
        expect(subject.kerberos_principal).to be_nil
      end
    end

    context "when sAMAccountName is defined (AD server)" do

      let(:sam_account_name) { "mylogin" }

      it "returns the principal combining sAMAccountName and DC components of the distinguishedName" do
        expect(subject.kerberos_principal).to eq("mylogin@BAR.COM")
      end
    end
  end

  describe "#ssh_keys" do

    let(:ssh_key) { "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrSQHff6a1rMqBdHFt+FwIbytMZ+hJKN3KLkTtOWtSvNIriGhnTdn4rs+tjD/w+z+revytyWnMDM9dS7J8vQi006B16+hc9Xf82crqRoPRDnBytgAFFQY1G/55ql2zdfsC5yvpDOFzuwIJq5dNGsojS82t6HNmmKPq130fzsenFnj5v1pl3OJvk513oduUyKiZBGTroWTn7H/eOPtu7s9MD7pAdEjqYKFLeaKmyidiLmLqQlCRj3Tl2U9oyFg4PYNc0bL5FZJ/Z6t0Ds3i/a2RanQiKxrvgu3GSnUKMx7WIX373baL4jeM7cprRGiOY/1NcS+1cAjfJ8oaxQF/1dYj" }
    let(:ssh_key_attribute_name) { 'altSecurityIdentities' }
    let(:entry) do
      Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com\n#{keys}")
    end

    subject { Gitlab::LDAP::Person.new(entry, 'ldapmain') }

    before do
      allow_any_instance_of(Gitlab::LDAP::Config).to receive_messages(sync_ssh_keys: ssh_key_attribute_name)
    end

    context "when the SSH key is literal" do

      let(:keys) { "#{ssh_key_attribute_name}: #{ssh_key}" }

      it "includes the SSH key" do
        expect(subject.ssh_keys).to include(ssh_key)
      end
    end

    context "when the SSH key is prefixed" do

      let(:keys) { "#{ssh_key_attribute_name}: SSHKey:#{ssh_key}" }

      it "includes the SSH key" do
        expect(subject.ssh_keys).to include(ssh_key)
      end
    end

    context "when the SSH key is suffixed" do

      let(:keys) { "#{ssh_key_attribute_name}: #{ssh_key} (SSH key)" }

      it "includes the SSH key" do
        expect(subject.ssh_keys).to include(ssh_key)
      end
    end

    context "when the SSH key is followed by a newline" do

      let(:keys) { "#{ssh_key_attribute_name}: #{ssh_key}\n" }

      it "includes the SSH key" do
        expect(subject.ssh_keys).to include(ssh_key)
      end
    end

    context "when the key is not an SSH key" do

      let(:keys) { "#{ssh_key_attribute_name}: KerberosKey:bogus" }

      it "is empty" do
        expect(subject.ssh_keys).to be_empty
      end
    end

    context "when there are multiple keys" do

      let(:keys) { "#{ssh_key_attribute_name}: #{ssh_key}\n#{ssh_key_attribute_name}: KerberosKey:bogus\n#{ssh_key_attribute_name}: ssh-rsa keykeykey" }

      it "includes both SSH keys" do
        expect(subject.ssh_keys).to include(ssh_key)
        expect(subject.ssh_keys).to include("ssh-rsa keykeykey")
        expect(subject.ssh_keys).not_to include("KerberosKey:bogus")
      end
    end
  end
end
