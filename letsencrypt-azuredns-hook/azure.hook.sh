#!/usr/bin/env bash

#
# How to deploy a DNS challenge using Azure
#

# Debug Logging level
DEBUG=4

# Azure Tenant specific configuration settings
#   You should create an SPN in Azure first and authorize it to make changes to Azure DNS
#       REF: https://azure.microsoft.com/en-us/documentation/articles/resource-group-create-service-principal-portal/
TENANT="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"      # Your tenant GUID
SPN_USERNAME="http://svc_letsencrypt"         # This is one of the SPN values (the identifier-uri or guid value)
#SPN_PASSWORD="<password>"                   # This is the password associated with the SPN account
RESOURCE_GROUP="grp_infra_dns"              # This is the resource group containing your Azure DNS instance
DNS_ZONE="example.com"                 # This is the DNS zone you want the SPN to manage (Contributor access)
TTL="3600"                                   # This is the TTL for the dnz record-set

if [ -z "${SPN_PASSWORD+xxx}" ]; then
    echo SPN_PASSWORD is not set
    exit 1
fi

# Supporting functions
function log {
    if [ $DEBUG -ge $2 ]; then
        echo "$1" > /dev/tty
    fi
}
function login_azure {
    # Azure DNS Connection Variables
    # You should create an SPN in Azure first and authorize it to make changes to Azure DNS
    #  REF: https://azure.microsoft.com/en-us/documentation/articles/resource-group-create-service-principal-portal/
    az login --service-principal -u ${SPN_USERNAME} -p ${SPN_PASSWORD} --tenant ${TENANT}
}
function parseSubDomain {
    log "  Parse SubDomain" 4

    FQDN="$1"
    log "    FQDN: '${FQDN}''" 4

    DOMAIN=$DNS_ZONE
    SUBDOMAIN=`sed -E "s/(.*)\.$DNS_ZONE/\1/" <<< "${FQDN}"`
    log "    SUBDOMAIN: '${SUBDOMAIN}'" 4

    echo "${SUBDOMAIN}"
    exit 1
}
function buildDnsKey {
    log "  Build DNS Key" 4

    FQDN="$1"
    log "    FQDN: '${FQDN}'" 4

    SUBDOMAIN=$(parseSubDomain ${FQDN})
    log "    SUBDOMAIN: ${SUBDOMAIN}" 4

    CHALLENGE_KEY="_acme-challenge.${SUBDOMAIN}"
    log "    KEY: '${CHALLENGE_KEY}'" 4

    echo "${CHALLENGE_KEY}"
}


# Logging the header
log "Azure Hook Script - LetsEncrypt" 4


# Execute the specified phase
PHASE="$1"
log "" 1
log "  Phase: '${PHASE}'" 1
#log "    Arguments: ${1} | ${2} | ${3} | ${4} | ${5} | ${6} | ${7} | ${8} | ${9} | ${10}" 1
case ${PHASE} in
    'deploy_challenge')
        login_azure

        # Arguments: PHASE; DOMAIN; TOKEN_FILENAME; TOKEN_VALUE
        FQDN="$2"
        TOKEN_VALUE="$4"
        SUBDOMAIN=$(parseSubDomain ${FQDN})
        CHALLENGE_KEY=$(buildDnsKey ${FQDN})

        # Commands
        log "" 4
        log "    Running azure cli commands" 4
        log "      Create: 'az network dns record-set txt create --if-none-match --resource-group ${RESOURCE_GROUP} --zone-name ${DNS_ZONE} -n ${CHALLENGE_KEY} --ttl ${TTL}" 4
        respCreate=$(az network dns record-set txt create --resource-group ${RESOURCE_GROUP} --zone-name ${DNS_ZONE} -n ${CHALLENGE_KEY} --ttl ${TTL})
        log " => '$respCreate'" 4
        log "      AddRec: 'az network dns record-set txt add-record --resource-group ${RESOURCE_GROUP} --zone-name ${DNS_ZONE} --record-set-name ${CHALLENGE_KEY} --value ${TOKEN_VALUE}'" 4
        respAddRec=$(az network dns record-set txt add-record --resource-group ${RESOURCE_GROUP} --zone-name ${DNS_ZONE} --record-set-name ${CHALLENGE_KEY} --value ${TOKEN_VALUE})
        log " => '$respAddRec'" 4
        ;;

    "clean_challenge")
        login_azure

        # Arguments: PHASE; DOMAIN; TOKEN_FILENAME; TOKEN_VALUE
        FQDN="$2"
        TOKEN_VALUE="$4"
        SUBDOMAIN=$(parseSubDomain ${FQDN})
        CHALLENGE_KEY=$(buildDnsKey ${FQDN})

        # Commands
        log "" 3
        log "    Running azure cli commands" 3
        respDel=$(az network dns record-set txt delete -y --resource-group ${RESOURCE_GROUP} --zone-name ${DNS_ZONE} --name ${CHALLENGE_KEY})
        log "      Delete: '$respDel'" 3
        ;;

    "deploy_cert")
        # Parameters:
        # - PHASE           - the phase being executed
        # - DOMAIN          - the domain name (CN or subject alternative name) being validated.
        # - KEY_PATH        - the path to the certificate's private key file
        # - CERT_PATH       - the path to the certificate file
        # - FULL_CHAIN_PATH - the path to the full chain file
        # - CHAIN_PATH      - the path to the chain file
        # - TIMESTAMP       - the timestamp of the deployment

        # do nothing for now
        ;;

    "unchanged_cert")
        # Parameters:
        # - PHASE           - the phase being executed
        # - DOMAIN          - the domain name (CN or subject alternative name) being validated.
        # - KEY_PATH        - the path to the certificate's private key file
        # - CERT_PATH       - the path to the certificate file
        # - FULL_CHAIN_PATH - the path to the full chain file
        # - CHAIN_PATH      - the path to the chain file

        # do nothing for now
        ;;

    *)
        ;;
esac

exit 0
