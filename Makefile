.PHONY: install test chaincode-check api controller odl-up odl-down

install:
	python3 -m venv .venv
	.venv/bin/pip install -r requirements-dev.txt

test:
	.venv/bin/pytest -q

chaincode-check:
	cd trustchain-smartcontract && go test ./...

api:
	cd blockchain-api && ../.venv/bin/python app.py

controller:
	.venv/bin/python sdn-controller/controller.py

odl-up:
	docker compose -f opendaylight/docker-compose.yml up -d

odl-down:
	docker compose -f opendaylight/docker-compose.yml down
