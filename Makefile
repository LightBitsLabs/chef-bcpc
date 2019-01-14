# -*- mode: Makefile -*-
# vim:list:listchars=tab\:>-:

export inventory = ansible/inventory
export playbooks = ansible/playbooks
export ANSIBLE_CONFIG = ansible/ansible.cfg

headnodes = $$(ansible headnodes -i ${inventory} --list | tail -n +2 | wc -l)
storagenodes = $$(ansible storagenodes -i ${inventory} --list | tail -n +2 | wc -l)

all : \
	download-assets \
	operator \
	configure-apt \
	configure-networking \
	chef-server \
	chef-workstation \
	chef-node \
	file-server \
	chef-client \
	add-cloud-images \
	register-compute-nodes

create :

	virtual/bin/create-virtual-environment.sh

create-network :

	virtual/bin/create-network.sh

destroy :

	virtual/bin/destroy-virtual-environment.sh

destroy-network :

	virtual/bin/destroy-network.sh

operator :

	ansible-playbook -v \
		-i ${inventory} ${playbooks}/site.yml \
		-t operator --limit cloud

configure-apt :

	ansible-playbook -v \
		-i ${inventory} ${playbooks}/site.yml \
		-t configure-apt --limit cloud

configure-networking :

	ansible-playbook -v \
		-i ${inventory} ${playbooks}/site.yml \
		-t configure-networking --limit cloud

download-assets :

	ansible-playbook -v \
		-i ${inventory} ${playbooks}/site.yml \
		-t download-assets --limit localhost

chef-server :

	ansible-playbook -v \
		-i ${inventory} ${playbooks}/site.yml \
		-t chef-server --limit bootstraps

chef-workstation :

	ansible-playbook -v \
		-i ${inventory} ${playbooks}/site.yml \
		-t chef-workstation --limit bootstraps

chef-node :

	ansible-playbook -v -i ${inventory} ${playbooks}/site.yml -t chef-node

chef-client : \
	chef-client-bootstraps \
	chef-client-headnodes \
	chef-client-worknodes \
	chef-client-storagenodes

chef-client-bootstraps :

	ansible-playbook -v \
		-i ${inventory} ${playbooks}/site.yml \
		-t chef-client --limit bootstraps

chef-client-headnodes :

	ansible-playbook -v \
		-i ${inventory} ${playbooks}/site.yml \
		-t chef-client --limit headnodes \
		-e "step=1"

	@if [ "${headnodes}" -gt 1 ]; then \
		ansible-playbook -v \
			-i ${inventory} ${playbooks}/site.yml \
			-t chef-client --limit headnodes \
			-e "step=1"; \
	fi

chef-client-worknodes :

	ansible-playbook -v \
		-i ${inventory} ${playbooks}/site.yml \
		-t chef-client --limit worknodes

chef-client-storagenodes :

	@if [ "${storagenodes}" -gt 0 ]; then \
		ansible-playbook -v \
			-i ${inventory} ${playbooks}/site.yml \
			-t chef-client --limit storagenodes; \
	fi

add-cloud-images:

	ansible-playbook -v \
		-i ${inventory} ${playbooks}/site.yml \
		-t add-cloud-images --limit headnodes

register-compute-nodes:

	ansible-playbook -v \
		-i ${inventory} ${playbooks}/site.yml \
		-t register-compute-nodes --limit headnodes

upload-bcpc :

	ansible-playbook -v \
		-i ${inventory} ${playbooks}/site.yml \
		-t upload-bcpc --limit bootstraps

upload-all :

	ansible-playbook -v \
		-i ${inventory} ${playbooks}/site.yml \
		-t upload-extra-cookbooks --limit bootstraps

	ansible-playbook -v \
		-i ${inventory} ${playbooks}/site.yml \
		-t upload-bcpc --limit bootstraps

file-server :

	ansible-playbook -v \
		-i ${inventory} ${playbooks}/site.yml \
		-t file-server --limit bootstraps

###############################################################################
# helper targets
###############################################################################

generate-chef-roles :

	ansible-playbook -v \
		-i ${inventory} ${playbooks}/site.yml \
		-t generate-chef-roles --limit bootstraps

adjust-ceph-pool-pgs:

	ansible-playbook -v \
		-i ${inventory} ${playbooks}/site.yml \
		-t adjust-ceph-pool-pgs --limit headnodes

ceph-destroy-osds:

	ansible-playbook -v \
		-i ${inventory} ${playbooks}/site.yml \
		-t ceph-destroy-osds \
		-e "destroy_osds=$(destroy_osds)" \
		--limit storagenodes
