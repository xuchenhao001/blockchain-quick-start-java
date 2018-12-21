package com.blockchain.quickstart.service.impl;

import com.blockchain.quickstart.service.FabricService;
import org.hyperledger.fabric.sdk.*;
import org.hyperledger.fabric.sdk.security.CryptoSuite;
import org.hyperledger.fabric_ca.sdk.Attribute;
import org.hyperledger.fabric_ca.sdk.HFCAClient;
import org.hyperledger.fabric_ca.sdk.HFCAInfo;
import org.hyperledger.fabric_ca.sdk.RegistrationRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.File;
import java.util.ArrayList;
import java.util.Collection;

@Service
public class FabricServiceImpl implements FabricService {

    private NetworkConfig networkConfig;

    private final static Logger logger = LoggerFactory.getLogger(FabricService.class);

    @Override
    public void installChaincode(String orgName, String chaincodeName, String chaincodeVersion) {

        try {
            UserContext user = getAdmin(orgName);
            HFClient client = getHfClient();
            client.setUserContext(user);

            Channel channel = client.loadChannelFromConfig("mychannel", networkConfig);

            Collection<Peer> peers = channel.getPeers();
            logger.debug("Get peers: " + peers.toString());

            InstallProposalRequest request = client.newInstallProposalRequest();

            ChaincodeID.Builder chaincodeIDBuilder = ChaincodeID.newBuilder().setName(chaincodeName)
                    .setVersion(chaincodeVersion).setPath("go");
            ChaincodeID chaincodeID = chaincodeIDBuilder.build();
            logger.info("Deploying chaincode " + chaincodeName + " using Fabric client " + client.getUserContext().getMspId()
                    + " " + client.getUserContext().getName());
            request.setChaincodeID(chaincodeID);
            request.setUserContext(client.getUserContext());
            request.setChaincodeSourceLocation(new File("./scaffold/chaincode"));
            request.setChaincodeVersion(chaincodeVersion);
            Collection<ProposalResponse> responses = client.sendInstallProposal(request, peers);
            for (ProposalResponse response : responses) {
                logger.debug(response.getMessage());
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void instantiateChaincode() {

    }

    @Override
    public void invokeChaincode(String name, String chaincodeFunction, String[] chaincodeArgs) {

    }

    @Override
    public String queryChaincode(String userName, Boolean idemixRole, Boolean regularEnroll) {
        try {

//            UserContext user = getAdmin("Org1");
            UserContext user;
            if (regularEnroll) {
                user = getAdmin("Org1");
            } else {
                user = enrollUser(userName, "Org1", idemixRole);
            }
            HFClient client = getHfClient();
            client.setUserContext(user);

            Channel channel = client.loadChannelFromConfig("mychannel", networkConfig);
            // in case EventHub error thrown in channel creation with multi-organization
            // Bug report: https://jira.hyperledger.org/browse/FABJ-175
            // See: https://github.com/davidkhala/fabric-sdk-android/blob/master/src/main/java/org/hyperledger/fabric/sdk/EventHub.java#L436
            Collection<EventHub> eventHubs = channel.getEventHubs();
            for (EventHub eventHub: eventHubs) {
                eventHub.setEventHubDisconnectedHandler(null);
            }
            channel.initialize();

            // create chaincode request
            QueryByChaincodeRequest request = client.newQueryProposalRequest();
            // build cc id providing the chaincode name. Version is omitted here.
            ChaincodeID fabcarCCId = ChaincodeID.newBuilder().setName("mycc").build();
            request.setChaincodeID(fabcarCCId);
            // CC function to be called
            request.setFcn("query");
            request.setArgs("a");
            Collection<ProposalResponse> proposalResponses = channel.queryByChaincode(request);

            // display response
            ArrayList<String> queryResponses = new ArrayList<>();
            for (ProposalResponse proposalResponse : proposalResponses) {
                if (!proposalResponse.isVerified() || proposalResponse.getStatus() != ProposalResponse.Status.SUCCESS) {
                    logger.debug("Failed query proposal from peer " + proposalResponse.getPeer().getName() + " status: "
                            + proposalResponse.getStatus() + ". Messages: " + proposalResponse.getMessage()
                            + ". Was verified : " + proposalResponse.isVerified());
                } else {
                    String payload = new String(proposalResponse.getChaincodeActionResponsePayload());
                    logger.info(payload);
                    queryResponses.add(payload);
                }
            }
            return queryResponses.toString();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private HFClient getHfClient() throws Exception {
        // initialize default cryptosuite
        CryptoSuite cryptoSuite = CryptoSuite.Factory.getCryptoSuite();
        // setup the client
        HFClient client = HFClient.createNewInstance();
        client.setCryptoSuite(cryptoSuite);
        return client;
    }

    // This method is not used at this time.
    // Parameters example: userName: user3, orgName: Org1
    private UserContext enrollUser(String userName, String orgName, Boolean idemixRole) throws Exception {
        networkConfig = NetworkConfig.fromYamlFile(new File("./src/main/resources/network-config.yaml"));
        NetworkConfig.OrgInfo org = networkConfig.getOrganizationInfo(orgName);
        NetworkConfig.CAInfo caInfo = org.getCertificateAuthorities().get(0);

        HFCAClient hfcaClient = HFCAClient.createNewInstance(caInfo);
        HFCAInfo info = hfcaClient.info();
        logger.debug("Get CA certificate chain: " + info.getCACertificateChain());

        Collection<NetworkConfig.UserInfo> registrars = caInfo.getRegistrars();
        NetworkConfig.UserInfo registrar = registrars.iterator().next();
//        Enrollment adminEnroll = hfcaClient.enroll(registrar.getName(), registrar.getEnrollSecret());
        Enrollment adminEnroll = hfcaClient.enroll("admin", "adminpw");
        registrar.setEnrollment(adminEnroll);

        UserContext context = new UserContext();
        context.setName(userName);
        // See: https://stackoverflow.com/questions/48836728/unable-to-enroll-user-in-new-org-added-to-balance-transfer-sample
        context.setAffiliation("org1.department1");
        context.setMspId(org.getMspId());
        RegistrationRequest rr = new RegistrationRequest(context.getName(), context.getAffiliation());

        // add role attribute with value 2
        if (idemixRole) {
            logger.debug("Set idemix role to admin");
            Attribute roleAttr = new Attribute("role", "2");
            rr.addAttribute(roleAttr);
        }

        String secret = hfcaClient.register(rr, registrar);
        logger.debug("Register user got secret: " + secret);
        Enrollment userEnroll = hfcaClient.enroll(context.getName(), secret);
//        context.setEnrollment(userEnroll);
        Enrollment idemixEnrollment = hfcaClient.idemixEnroll(userEnroll, "idemixMSPID1");
        context.setEnrollment(idemixEnrollment);

        return context;
    }

    private UserContext getAdmin(String orgName) throws Exception {
        networkConfig = NetworkConfig.fromYamlFile(new File("./src/main/resources/network-config.yaml"));
        NetworkConfig.OrgInfo org = networkConfig.getOrganizationInfo(orgName);
        NetworkConfig.CAInfo caInfo = org.getCertificateAuthorities().get(0);

        HFCAClient hfcaClient = HFCAClient.createNewInstance(caInfo);
        HFCAInfo info = hfcaClient.info();
        logger.debug("Get CA certificate chain: " + info.getCACertificateChain());

        Collection<NetworkConfig.UserInfo> registrars = caInfo.getRegistrars();
        NetworkConfig.UserInfo registrar = registrars.iterator().next();
        UserContext context = new UserContext();
        context.setName("admin");
        context.setAffiliation("org1.department1");
        context.setMspId(org.getMspId());
//        Enrollment enrollment = hfcaClient.enroll(registrar.getName(), registrar.getEnrollSecret());
        Enrollment enrollment = hfcaClient.enroll(registrar.getName(), registrar.getEnrollSecret());
        context.setEnrollment(enrollment);
        return context;
    }

}
