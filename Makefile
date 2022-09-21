DOCKER := docker

SOLC     := ethereum/solc:0.8.17
SOLFLAGS := --metadata-hash none --optimize --optimize-runs 1000000

CONTRACTS := SolverTrampoline
ARTIFACTS := $(patsubst %,contracts/build/%.json,$(CONTRACTS))

.PHONY: run
run: contracts
	deno run \
		--allow-env=INFURA_PROJECT_ID,TENDERLY_USER,TENDERLY_PROJECT,TENDERLY_API_KEY \
		--allow-net=mainnet.infura.io,api.tenderly.co \
		src/index.js

.PHONY: contracts
contracts: $(ARTIFACTS)

contracts/build/%.json: contracts/%.sol
	mkdir -p contracts/build
	docker run -it --rm \
		-v "$(abspath contracts):/src" -w "/src" \
		${SOLC} ${SOLFLAGS} \
		--overwrite --combined-json abi,bin --output-dir . \
		$*.sol
	cat contracts/combined.json | jq '.contracts["$*.sol:$*"]' > $@
	rm -f contracts/combined.json
