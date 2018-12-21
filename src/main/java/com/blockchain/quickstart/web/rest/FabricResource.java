package com.blockchain.quickstart.web.rest;

import com.blockchain.quickstart.service.FabricService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class FabricResource {

    private final static Logger logger = LoggerFactory.getLogger(FabricResource.class);

    @Autowired
    FabricService fabricService;

    @GetMapping(value = "/test/install", produces = "application/json")
    public ResponseEntity<String> installChaincode(
            @RequestParam("orgName") String orgName,
            @RequestParam("chaincodeName") String chaincodeName,
            @RequestParam("chaincodeVersion") String chaincodeVersion) {
        logger.debug("REST request to install chaincode");

        fabricService.installChaincode(orgName, chaincodeName, chaincodeVersion);

        return ResponseEntity.ok("");
    }

    @GetMapping(value = "/test/init", produces = "application/json")
    public ResponseEntity<String> initChaincode() {
        logger.debug("REST request to instantiate chaincode");

        fabricService.instantiateChaincode();

        return ResponseEntity.ok("");
    }

    @GetMapping(value = "/test/query", produces = "application/json")
    public ResponseEntity<String> queryChaincode(
            @RequestParam("userName") String userName,
            @RequestParam("idemixRole") Boolean idemixRole,
            @RequestParam("regularEnroll") Boolean regularEnroll) {

        logger.debug("REST request to query chaincode");

        String response = fabricService.queryChaincode(userName, idemixRole, regularEnroll);

        return ResponseEntity.ok(response);
    }
}
