package main

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// TrustChainContract defines the smart contract
type TrustChainContract struct {
	contractapi.Contract
}

// SDNPolicy represents a blockchain-stored SDN policy
type SDNPolicy struct {
	PolicyID    string `json:"policyID"`
	TenantID    string `json:"tenantID"`
	Source      string `json:"source"`
	Destination string `json:"destination"`
	Action      string `json:"action"`
	Priority    int    `json:"priority"`
	Status      string `json:"status"`
	CreatedBy   string `json:"createdBy"`
}

// CreatePolicy stores a new SDN policy on the blockchain
func (t *TrustChainContract) CreatePolicy(
	ctx contractapi.TransactionContextInterface,
	policyID string,
	tenantID string,
	source string,
	destination string,
	action string,
	priority int,
	createdBy string,
) error {

	exists, err := t.PolicyExists(ctx, policyID)

	if err != nil {
		return err
	}

	if exists {
		return fmt.Errorf("policy %s already exists", policyID)
	}

	policy := SDNPolicy{
		PolicyID:    policyID,
		TenantID:    tenantID,
		Source:      source,
		Destination: destination,
		Action:      action,
		Priority:    priority,
		Status:      "ACTIVE",
		CreatedBy:   createdBy,
	}

	policyJSON, err := json.Marshal(policy)

	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(policyID, policyJSON)
}

// ReadPolicy retrieves an SDN policy
func (t *TrustChainContract) ReadPolicy(
	ctx contractapi.TransactionContextInterface,
	policyID string,
) (*SDNPolicy, error) {

	policyJSON, err := ctx.GetStub().GetState(policyID)

	if err != nil {
		return nil, err
	}

	if policyJSON == nil {
		return nil, fmt.Errorf("policy %s does not exist", policyID)
	}

	var policy SDNPolicy

	err = json.Unmarshal(policyJSON, &policy)

	if err != nil {
		return nil, err
	}

	return &policy, nil
}

// PolicyExists checks if a policy exists
func (t *TrustChainContract) PolicyExists(
	ctx contractapi.TransactionContextInterface,
	policyID string,
) (bool, error) {

	policyJSON, err := ctx.GetStub().GetState(policyID)

	if err != nil {
		return false, err
	}

	return policyJSON != nil, nil
}

// Main starts the chaincode
func main() {

	chaincode, err := contractapi.NewChaincode(&TrustChainContract{})

	if err != nil {
		panic(err.Error())
	}

	if err := chaincode.Start(); err != nil {
		panic(err.Error())
	}
}
