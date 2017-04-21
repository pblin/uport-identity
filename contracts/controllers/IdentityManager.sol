pragma solidity ^0.4.4;
import "../proxies/Proxy.sol";

contract IdentityManager {
  event IdentityCreated(
    address indexed identity,
    address indexed creator,
    address owner,
    address indexed recoveryKey);

  event OwnerAdded(
    address indexed identity,
    address indexed owner,
    address instigator);

  event OwnerRemoved(
    address indexed identity,
    address indexed owner,
    address instigator);

  event RecoveryChanged(
    address indexed identity,
    address indexed recoveryKey,
    address instigator);

  mapping(address => mapping(address => uint)) owners;
  mapping(address => address) recoveryKeys;

  modifier onlyOwner(address identity) { 
    if (owners[identity][msg.sender] > 0 && owners[identity][msg.sender] <= now ) _; 
  }

  modifier onlyOlderOwner(address identity) { 
    if (owners[identity][msg.sender] > 0 && (owners[identity][msg.sender] + 1 days) <= now) _; 
  }

  modifier onlyRecovery(address identity) { 
    if (recoveryKeys[identity] == msg.sender) _; 
  }

  // Factory function
  // gas 289,311
  function CreateIdentity(address owner, address recoveryKey) {
    Proxy identity = new Proxy();
    owners[identity][owner] = now - 1 days; // This is to ensure original owner has full power from day one
    recoveryKeys[identity] = recoveryKey;
    IdentityCreated(identity, msg.sender, owner,  recoveryKey);
  }

  function forwardTo(Proxy identity, address destination, uint value, bytes data) onlyOwner(identity) {
    identity.forward(destination, value, data);
  }

  // an owner can add a new device instantly
  function addOwner(Proxy identity, address newOwner) onlyOlderOwner(identity) {
    owners[identity][newOwner] = now;
    OwnerAdded(identity, newOwner, msg.sender);
  }

  // a recovery key owner can add a new device with 1 days wait time
  function addOwnerForRecovery(Proxy identity, address newOwner) onlyRecovery(identity) {
    if (owners[identity][newOwner] > 0) throw;
    owners[identity][newOwner] = now + 1 days;
    OwnerAdded(identity, newOwner, msg.sender);
  }

  // an owner can remove another owner instantly
  function removeOwner(Proxy identity, address owner) onlyOlderOwner(identity) {
    owners[identity][owner] = 0;
    OwnerRemoved(identity, owner, msg.sender);
  }

  // an owner can add change the recoverykey whenever they want to
  function changeRecovery(Proxy identity, address recoveryKey) onlyOlderOwner(identity) {
    recoveryKeys[identity] = recoveryKey;
    RecoveryChanged(identity, recoveryKey, msg.sender);
  }

}
