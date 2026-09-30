zksyncBuild:
		FOUNDRY_PROFILE=zksync forge build --zksync  --system-mode=true -vvvv

zkTestMt:
		FOUNDRY_PROFILE=zksync forge test --mt $(TEST) --zksync  --system-mode=true 
