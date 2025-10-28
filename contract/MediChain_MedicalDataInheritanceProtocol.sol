// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Project {
    
    struct MedicalRecord {
        string recordHash; // IPFS hash or encrypted data reference
        uint256 timestamp;
        bool exists;
    }
    
    struct Beneficiary {
        address beneficiaryAddress;
        uint256 accessGrantedTime;
        bool isActive;
    }
    
    mapping(address => MedicalRecord[]) private patientRecords;
    mapping(address => Beneficiary[]) private patientBeneficiaries;
    mapping(address => bool) public isDeceased;
    mapping(address => address) public nominatedExecutor;
    
    event RecordAdded(address indexed patient, string recordHash, uint256 timestamp);
    event BeneficiaryAdded(address indexed patient, address indexed beneficiary);
    event AccessGranted(address indexed patient, address indexed beneficiary);
    event PatientMarkedDeceased(address indexed patient, address indexed executor);
    
    // CORE FUNCTION 1: Add Medical Records
    function addMedicalRecord(string memory _recordHash) public {
        require(!isDeceased[msg.sender], "Cannot add records for deceased patient");
        
        patientRecords[msg.sender].push(MedicalRecord({
            recordHash: _recordHash,
            timestamp: block.timestamp,
            exists: true
        }));
        
        emit RecordAdded(msg.sender, _recordHash, block.timestamp);
    }
    
    // CORE FUNCTION 2: Nominate Beneficiaries
    function nominateBeneficiary(address _beneficiary) public {
        require(_beneficiary != address(0), "Invalid beneficiary address");
        require(!isDeceased[msg.sender], "Cannot nominate beneficiaries after death");
        
        patientBeneficiaries[msg.sender].push(Beneficiary({
            beneficiaryAddress: _beneficiary,
            accessGrantedTime: 0,
            isActive: true
        }));
        
        emit BeneficiaryAdded(msg.sender, _beneficiary);
    }
    
    // CORE FUNCTION 3: Mark Patient as Deceased & Grant Access
    function markDeceasedAndGrantAccess(address _patient) public {
        require(nominatedExecutor[_patient] == msg.sender, "Only nominated executor can mark deceased");
        require(!isDeceased[_patient], "Patient already marked as deceased");
        
        isDeceased[_patient] = true;
        
        // Grant access to all beneficiaries
        for (uint i = 0; i < patientBeneficiaries[_patient].length; i++) {
            if (patientBeneficiaries[_patient][i].isActive) {
                patientBeneficiaries[_patient][i].accessGrantedTime = block.timestamp;
            }
        }
        
        emit PatientMarkedDeceased(_patient, msg.sender);
    }
    
    // Helper Function: Set Executor
    function setExecutor(address _executor) public {
        require(_executor != address(0), "Invalid executor address");
        require(!isDeceased[msg.sender], "Cannot set executor after death");
        
        nominatedExecutor[msg.sender] = _executor;
    }
    
    // Helper Function: View Medical Records (only beneficiaries after death)
    function viewMedicalRecords(address _patient) public view returns (MedicalRecord[] memory) {
        require(isDeceased[_patient], "Patient must be deceased to access records");
        
        bool isBeneficiary = false;
        for (uint i = 0; i < patientBeneficiaries[_patient].length; i++) {
            if (patientBeneficiaries[_patient][i].beneficiaryAddress == msg.sender && 
                patientBeneficiaries[_patient][i].isActive) {
                isBeneficiary = true;
                break;
            }
        }
        
        require(isBeneficiary, "Only beneficiaries can access records");
        
        return patientRecords[_patient];
    }
    
    // Helper Function: View own records
    function viewMyRecords() public view returns (MedicalRecord[] memory) {
        return patientRecords[msg.sender];
    }
}

