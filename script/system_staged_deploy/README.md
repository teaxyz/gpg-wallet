# Dev Deploy

## Tasks

If using ledger device add `--ledger --hd-paths "m/44'/60'/0'/0/0"` prior to `--broadcast`

### deploy

```sh
forge script/system_staged_deploy/0_DeployHelper_Deploy.s.sol --broadcast --rpc-url ${BASE_SEPOLIA_RPC} --sender ${SENDER_ADDRESS}
```
