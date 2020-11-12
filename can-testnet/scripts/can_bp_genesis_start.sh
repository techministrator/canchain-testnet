#!/bin/bash
DATADIR="./canchain"

## Required Environment Variables: BPACCOUNT, PUBKEY, PRIKEY 

# Create Wallet and Import Private Key
if [ ! -d /root/eosio-wallet ]; then 
  cleos wallet create --file /root/wallet_pass.txt
  sleep 3
  cleos wallet import --private-key $PRIKEY
fi 

ls $DATADIR || mkdir -p $DATADIR

nodeos \
--genesis-json "./genesis.json" \
--signature-provider $PUBKEY=KEY:$PRIKEY \
--producer-name $BPACCOUNT \
--plugin eosio::producer_plugin \
--plugin eosio::producer_api_plugin \
--plugin eosio::chain_api_plugin \
--plugin eosio::http_plugin \
--plugin eosio::http_client_plugin \
--plugin eosio::net_plugin \
--data-dir $DATADIR"/data" \
--blocks-dir $DATADIR"/blocks" \
--config-dir $DATADIR"/config" \
--http-server-address 127.0.0.1:8888 \
--p2p-listen-endpoint 0.0.0.0:9010 \
--access-control-allow-origin=* \
--max-transaction-time 45 \
--contracts-console \
--http-validate-host=false \
--verbose-http-errors \
--enable-stale-production \
${GENESIS_PEER:+--p2p-peer-address $GENESIS_PEER:9010} \
${PEER1:+--p2p-peer-address $PEER1:9010} \
${PEER2:+--p2p-peer-address $PEER2:9010} \
${PEER3:+--p2p-peer-address $PEER3:9010} \
>> $DATADIR"/nodeos.log" 2>&1 & \
echo $! > $DATADIR"/eosd.pid"