#!/bin/bash

set -e

# Generates Org certs using cryptogen tool
function generateCerts (){
  echo
  echo "===== Generate certificates using cryptogen tool ========="
  echo
  if [ -d "./crypto-config" ]; then
    rm -Rf ./crypto-config
  fi
  cryptogen generate --config=./crypto-config.yaml --output=./crypto-config
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate certificates..."
    exit 1
  fi
  echo "Finished."
}

# Using docker-compose-e2e-template.yaml, replace constants with private key file names
# generated by the cryptogen tool and output a docker-compose.yaml specific to this
# configuration
function prepareCAFile () {
  echo
  echo "===== Prepare CA Cert files ========="
  echo
  # Copy the template to the file that will be modified to add the private key
  cp docker-compose-e2e-template.yaml docker-compose-e2e.yaml

  # The next steps will replace the template's contents with the
  # actual values of the private key file names for the two CAs.
  CURRENT_DIR=$PWD

  cd crypto-config/peerOrganizations/org1.example.com/ca/
  PRIV_KEY=$(ls *_sk)
  cd "$CURRENT_DIR"
  sed -i "s/CA1_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-e2e.yaml

  cd crypto-config/peerOrganizations/org2.example.com/ca/
  PRIV_KEY=$(ls *_sk)
  cd "$CURRENT_DIR"
  sed -i "s/CA2_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-e2e.yaml

  # cd crypto-config/peerOrganizations/org3.example.com/ca/
  # PRIV_KEY=$(ls *_sk)
  # cd "$CURRENT_DIR"
  # sed -i "s/CA3_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-e2e.yaml

  echo "Finished."
}

# Got a path parameter, and then return it's content parsed with '\n'
function getFileParse() {
  local FILEPATH=$1
  local CONTENT=$(cat -E $FILEPATH)
  local CONTENT=$(echo $CONTENT | sed 's/\$ */\\\\n/g')
  local CONTENT=$(echo $CONTENT | sed 's/\//\\\//g')
  echo $CONTENT
}

function prepareConnectionFileCerts() {
  echo
  echo "===== Prepare network connection profile ========="
  echo
  cp ../src/main/resources/network-config-template.yaml ../src/main/resources/network-config.yaml
  configFile="../src/main/resources/network-config.yaml"

  # Org1 Admin
  PRIV_KEY=$(getFileParse crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/*_sk)
  sed -i "s/ORG1_PRIVATE_KEY/${PRIV_KEY}/g" "$configFile"
  ADMIN_CERT=$(getFileParse crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem)
  sed -i "s/ORG1_SIGN_CERT/${ADMIN_CERT}/g" "$configFile"

  # Org2 Admin
  PRIV_KEY=$(getFileParse crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/keystore/*_sk)
  sed -i "s/ORG2_PRIVATE_KEY/${PRIV_KEY}/g" "$configFile"
  ADMIN_CERT=$(getFileParse crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/signcerts/Admin@org2.example.com-cert.pem)
  sed -i "s/ORG2_SIGN_CERT/${ADMIN_CERT}/g" "$configFile"

  # Org3 Admin
  # PRIV_KEY=$(getFileParse crypto-config/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp/keystore/*_sk)
  # sed -i "s/ORG3_PRIVATE_KEY/${PRIV_KEY}/g" "$configFile"
  # ADMIN_CERT=$(getFileParse crypto-config/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp/signcerts/Admin@org3.example.com-cert.pem)
  # sed -i "s/ORG3_SIGN_CERT/${ADMIN_CERT}/g" "$configFile"

  # Orderer tls CA
  ORDERER_TLS=$(getFileParse crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt)
  sed -i "s/ORDERER_TLS/$ORDERER_TLS/g" "$configFile"

  # peers' tls CA
  PEER0_ORG1_TLS=$(getFileParse crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt)
  sed -i "s/PEER0_ORG1_TLS/$PEER0_ORG1_TLS/g" "$configFile"
  PEER1_ORG1_TLS=$(getFileParse crypto-config/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt)
  sed -i "s/PEER1_ORG1_TLS/$PEER1_ORG1_TLS/g" "$configFile"
  PEER0_ORG2_TLS=$(getFileParse crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt)
  sed -i "s/PEER0_ORG2_TLS/$PEER0_ORG2_TLS/g" "$configFile"
  PEER1_ORG2_TLS=$(getFileParse crypto-config/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/ca.crt)
  sed -i "s/PEER1_ORG2_TLS/$PEER1_ORG2_TLS/g" "$configFile"
  # PEER0_ORG3_TLS=$(getFileParse crypto-config/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt)
  # sed -i "s/PEER0_ORG3_TLS/$PEER0_ORG3_TLS/g" "$configFile"
  # PEER1_ORG3_TLS=$(getFileParse crypto-config/peerOrganizations/org3.example.com/peers/peer1.org3.example.com/tls/ca.crt)
  # sed -i "s/PEER1_ORG3_TLS/$PEER1_ORG3_TLS/g" "$configFile"

  # CA's tls CA
  CA_ORG1_TLS=$(getFileParse crypto-config/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem)
  sed -i "s/CA_ORG1_TLS/$CA_ORG1_TLS/g" "$configFile"
  CA_ORG2_TLS=$(getFileParse crypto-config/peerOrganizations/org2.example.com/ca/ca.org2.example.com-cert.pem)
  sed -i "s/CA_ORG2_TLS/$CA_ORG2_TLS/g" "$configFile"
  # CA_ORG3_TLS=$(getFileParse crypto-config/peerOrganizations/org3.example.com/ca/ca.org3.example.com-cert.pem)
  # sed -i "s/CA_ORG3_TLS/$CA_ORG3_TLS/g" "$configFile"

  # cp ../config/network-config-ext-template.yaml ../config/network-config-ext.yaml
  echo "Finished."
}

# Generate orderer genesis block, channel configuration transaction and
# anchor peer update transactions
function generateGenesisBlock() {
  if [ -d "./channel-artifacts" ]; then
    rm -Rf ./channel-artifacts
  fi
  mkdir -p ./channel-artifacts
  echo
  echo "===== Generating Orderer Genesis block ========="
  echo
  # Note: For some unknown reason (at least for now) the block file can't be
  # named orderer.genesis.block or the orderer will fail to launch!
  set -x
  rm -rf idemix-config
  idemixgen ca-keygen
  idemixgen signerconfig -u OrgUnit1 --admin -e "johndoe" -r 1234
  mkdir -p crypto-config/peerOrganizations/org3.example.com
  cp -r idemix-config/* crypto-config/peerOrganizations/org3.example.com/
  rm -rf idemix-config
  idemixgen ca-keygen
  idemixgen signerconfig -u OrgUnit2 --admin -e "johndoe" -r 1234
  mkdir -p crypto-config/peerOrganizations/org4.example.com
  cp -r idemix-config/* crypto-config/peerOrganizations/org4.example.com/
  rm -rf idemix-config

  configtxgen --configPath ./ -profile TwoOrgsOrdererGenesis_v13 -outputBlock ./channel-artifacts/genesis.block
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
  fi
  echo "Finished."
}

function generateChannelArtifacts() {
  echo "##########################################################"
  echo "#########  Generating Orderer Genesis block ##############"
  echo "##########################################################"
  # Note: For some unknown reason (at least for now) the block file can't be
  # named orderer.genesis.block or the orderer will fail to launch!
  set -x
  configtxgen -profile TwoOrgsOrdererGenesis_v13 -outputBlock ./channel-artifacts/genesis.block
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
  fi
  echo
  echo "#################################################################"
  echo "### Generating channel configuration transaction 'channel.tx' ###"
  echo "#################################################################"
  set -x
  configtxgen -profile TwoOrgsChannel_v13 -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID mychannel
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi

  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for Org1MSP   ##########"
  echo "#################################################################"
  set -x
  configtxgen -profile TwoOrgsChannel_v13 -outputAnchorPeersUpdate \
    ./channel-artifacts/Org1MSPanchors.tx -channelID mychannel -asOrg Org1MSP
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate anchor peer update for Org1MSP..."
    exit 1
  fi

  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for Org2MSP   ##########"
  echo "#################################################################"
  set -x
  configtxgen -profile TwoOrgsChannel_v13 -outputAnchorPeersUpdate \
    ./channel-artifacts/Org2MSPanchors.tx -channelID mychannel -asOrg Org2MSP
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate anchor peer update for Org2MSP..."
    exit 1
  fi
  echo
}

function prepareEnv() {
  echo
  echo "===== Prepare Rest Server container/dev environment ========="
  echo
  # your running env is container or dev
  read -p "If you want run in container? (Y/n): " RUN_ENV
  if [[ $RUN_ENV = "N" || $RUN_ENV = "n" ]]; then
    # in dev mode, reset certs' path
    # CURRENT_DIR=$(echo $DEV_PATH | sed "s/\//\\\\\//g")
    # sed -i "s/\/var/$CURRENT_DIR/g" ../config/network-config-ext.yaml

    # in dev mode, reset url
    configFile="../src/main/resources/network-config.yaml"
    sed -i "s/orderer.example.com:7050/localhost:7050/g" "$configFile"
    sed -i "s/peer0.org1.example.com:7051/localhost:7051/g" "$configFile"
    sed -i "s/peer0.org1.example.com:7053/localhost:7053/g" "$configFile"
    sed -i "s/peer1.org1.example.com:7051/localhost:8051/g" "$configFile"
    sed -i "s/peer1.org1.example.com:7053/localhost:8053/g" "$configFile"
    sed -i "s/peer0.org2.example.com:7051/localhost:9051/g" "$configFile"
    sed -i "s/peer0.org2.example.com:7053/localhost:9053/g" "$configFile"
    sed -i "s/peer1.org2.example.com:7051/localhost:10051/g" "$configFile"
    sed -i "s/peer1.org2.example.com:7053/localhost:10053/g" "$configFile"
    # sed -i "s/peer0.org3.example.com:7051/localhost:11051/g" "$configFile"
    # sed -i "s/peer0.org3.example.com:7053/localhost:11053/g" "$configFile"
    # sed -i "s/peer1.org3.example.com:7051/localhost:12051/g" "$configFile"
    # sed -i "s/peer1.org3.example.com:7053/localhost:12053/g" "$configFile"
    sed -i "s/ca.org1.example.com:7054/localhost:7054/g" "$configFile"
    sed -i "s/ca.org2.example.com:7054/localhost:8054/g" "$configFile"
    # sed -i "s/ca.org3.example.com:7054/localhost:9054/g" "$configFile"
  fi
  echo "Finished."
}

# Generate the needed certificates, the genesis block and start the network.
function networkUp() {
  docker-compose -f docker-compose-e2e.yaml up -d 2>&1
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to start network"
    exit 1
  fi
  # now run the end to end script
  docker exec cli scripts/script.sh mychannel 3 golang 10 true
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Test failed"
    exit 1
  fi
}

generateCerts
prepareCAFile
prepareConnectionFileCerts
generateGenesisBlock
generateChannelArtifacts
prepareEnv
networkUp
