.PHONY: install

install:
	if [ -e ../../.overcommit.yml ]; then cp -f ../../.overcommit.yml ../../.overcommit.yml.backup; fi
	cp ../../.overcommit.yml.example ../../.overcommit.yml
	bundle install
	cd ../../ && overcommit -i
