#!/bin/bash
. utils.sh

set -e

if [ $# -ne 3 ]; then
  echo "Usage: $0 <money wallet json file> <auth addr starts with> <mint addr starts with>"
  exit 1
fi

FEE_PAYER=$1
AUTH_STARTS_WITH=$2
MINT_STARTS_WITH=$3

# Set solana back to main-net
solana config set --url mainnet-beta

# Generate authority keypair
TOKEN_AUTH_JSON=$(solana-keygen grind --starts-with "$AUTH_STARTS_WITH:1" | tail -n 1 | cut -d " " -f 4)
TOKEN_AUTH_ADDR=$(echo "$TOKEN_AUTH_JSON" | cut -d "." -f 1)

# Set keypair
solana config set --keypair "$TOKEN_AUTH_JSON"

# Generate mint keypair
MINT_JSON=$(solana-keygen grind --starts-with "$MINT_STARTS_WITH:1" | tail -n 1 | cut -d " " -f 4)
MINT_ADDR=$(echo "$MINT_JSON" | cut -d "." -f 1)

# Create the token COSTS MONEY
spl-token create-token \
  --program-id TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb \
  --enable-metadata \
  --decimals 9 \
  "$MINT_JSON" \
  --fee-payer "$FEE_PAYER"

# Initialize metadata
spl-token initialize-metadata \
  "$MINT_ADDR" \
  "TeslaAI" \
  "TESLAAI" \
  "https://binklemeyer.github.io/token-data/tesla-metadata.json" \
  --fee-payer "$FEE_PAYER"

# Create account for mint
spl-token create-account "$MINT_ADDR" --fee-payer "$FEE_PAYER"

# Mint tokens
spl-token mint "$MINT_ADDR" 1000000000 --fee-payer "$FEE_PAYER"

TOKEN_ACCOUNT_ADDR=$(spl-token accounts --owner "$TOKEN_AUTH_ADDR" --output json \
  | jq -r '.accounts[] | select(.mint == "'"$MINT_ADDR"'") | .address')

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Token address: ${TOKEN_ACCOUNT_ADDR}"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

# Burn tokens
#spl-token burn "$TOKEN_ACCOUNT_ADDR" 100000000 \
#  --owner "$TOKEN_AUTH_JSON" \
#  --fee-payer "$FEE_PAYER"

# Lock permissions
DISABLE_MINT=(spl-token authorize "$MINT_ADDR" mint --disable --fee-payer "$FEE_PAYER")
call_to_success 5 "${DISABLE_MINT[@]}"
DISABLE_META=(spl-token authorize "$MINT_ADDR" metadata --disable --fee-payer "$FEE_PAYER")
call_to_success 5 "${DISABLE_META[@]}"
DISABLE_POINTER=(spl-token authorize "$MINT_ADDR" metadata-pointer --disable --fee-payer "$FEE_PAYER")
call_to_success 5 "${DISABLE_POINTER[@]}"

# Create $BARRON account on fee-payer
spl-token create-account $MINT_ADDR --owner $FEE_PAYER --fee-payer $FEE_PAYER

FEE_PAYER_ADDR=$(solana-keygen pubkey $FEE_PAYER)

spl-token transfer \
  --from "$TOKEN_ACCOUNT_ADDR" \
  --owner "$TOKEN_AUTH_JSON" \
  "$MINT_ADDR" \
  1000000000 \
  $FEE_PAYER_ADDR \
  --fee-payer $FEE_PAYER 

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Mint address: ${MINT_ADDR}"
echo "Auth address: ${TOKEN_AUTH_ADDR}"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
