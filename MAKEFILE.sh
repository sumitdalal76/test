NAMESPACE=etcd
CERTS_DIR=tls-setup/certs

#install
.PHONY: install-etcd
install-etcd: create-etcd-namespace install-etcd-secret setup-etcd init-etcd

.PHONY: create-etcd-namespace
create-etcd-namespace:
	kubectl create namespace $(NAMESPACE)

.PHONY: install-etcd-secret
install-etcd-secret:
	@kubectl create secret generic etcd-root-password --from-literal=etcd-root-password=$(ETCD_ROOT_PASSWORD) -n $(NAMESPACE)

.PHONY: setup-etcd
setup-etcd:
	helm install etcd charts/etcd/ -n $(NAMESPACE)
	sleep 150
	#refresh pods
	kubectl delete pods etcd-0 etcd-1 etcd-2 etcd-3 etcd-4 -n $(NAMESPACE)
	sleep 60

.PHONY: init-etcd
init-etcd:
	#export ETCD_ROOT_PASSWORD=$(kubectl get secret --namespace etcd etcd-root-password -o jsonpath="{.data.etcd-root-password}" | base64 --decode)
	@kubectl exec etcd-0 -n $(NAMESPACE) -- bash -c "etcdctl role add root && etcdctl user add root:$(ETCD_ROOT_PASSWORD) && etcdctl user  grant-role  root root && etcdctl auth enable"

#uninstall

.PHONY: uninstall-etcd
uninstall-etcd: 
	@echo -n "Uninstall etcd and delete $(NAMESPACE) namespace. Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	helm uninstall etcd -n $(NAMESPACE)
	kubectl delete namespace $(NAMESPACE)

.PHONY: delete-etcd-secret
delete-etcd-secret:
	kubectl delete secret etcd-root-password -n $(NAMESPACE)

.PHONY: delete-data
delete-data:
	kubectl delete pvc data-etcd-0 data-etcd-1 data-etcd-2 data-etcd-3 data-etcd-4 -n $(NAMESPACE)

.PHONY: purge-etcd
purge-etcd: uninstall-etcd