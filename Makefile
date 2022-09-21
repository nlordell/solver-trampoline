DOCKER := docker

SOLC     := ethereum/solc:0.8.17
SOLFLAGS := --metadata-hash none --optimize --optimize-runs 1000000

CONTRACTS := SolverTrampoline
ARTIFACTS := $(patsubst %,contracts/build/%.json,$(CONTRACTS))

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
