package com.blockchain.quickstart.service;

public interface FabricService {

    void installChaincode(String orgName, String chaincodeName, String chaincodeVersion);

    void instantiateChaincode();

    void invokeChaincode(String name, String chaincodeFunction, String[] chaincodeArgs);

    String queryChaincode(String userName, Boolean idemixRole, Boolean regularEnroll);

}
