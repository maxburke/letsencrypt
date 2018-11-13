#!/bin/bash
../dehydrated/dehydrated --register --accept-terms --config ./config.sh
../dehydrated/dehydrated -c --config ./config.sh -k ../letsencrypt-azuredns-hook/azure.hook.sh
