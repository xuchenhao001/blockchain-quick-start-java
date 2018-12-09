package com.blockchain.quickstart.service;

public interface FabricService {

    void invokeChaincode(String name, String chaincodeFunction, String[] chaincodeArgs);

    String queryChaincode();

}
