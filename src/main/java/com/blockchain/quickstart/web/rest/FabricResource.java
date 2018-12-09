package com.blockchain.quickstart.web.rest;

import com.blockchain.quickstart.service.FabricService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class FabricResource {

    private final static Logger logger = LoggerFactory.getLogger(FabricResource.class);

    @Autowired
    FabricService fabricService;

    @GetMapping(value = "/test", produces = "application/json")
    public ResponseEntity<String> queryChaincode() {
        logger.debug("REST request to query chaincode");

        String response = fabricService.queryChaincode();

        return ResponseEntity.ok(response);
    }
}
