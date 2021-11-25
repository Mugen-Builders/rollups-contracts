// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Ether Portal Implementation
pragma solidity ^0.8.0;

import "./EtherPortal.sol";
import "./Input.sol";

contract EtherPortalImpl is EtherPortal {
    address immutable outputContract;
    Input immutable inputContract;

    modifier onlyOutputContract {
        require(msg.sender == outputContract, "only outputContract");
        _;
    }

    constructor(address _inputContract, address _outputContract) {
        inputContract = Input(_inputContract);
        outputContract = _outputContract;
    }

    /// @notice deposit an amount of Ether in the portal contract and create Ether in L2
    /// @param _data information to be interpreted by L2
    /// @return hash of input generated by deposit
    function etherDeposit(
        bytes calldata _data
    ) public payable override returns (bytes32) {
        bytes memory input =
            abi.encode(msg.sender, msg.value, _data);

        emit EtherDeposited(msg.sender, msg.value, _data);
        return inputContract.addInput(input);
    }

    /// @notice executes a rollups voucher
    /// @param _data data with information necessary to execute voucher
    /// @dev can only be called by the Output contract
    function executeRollupsVoucher(bytes calldata _data)
        public
        override
        onlyOutputContract
        returns (bool)
    {
        (
            address payable receiver,
            uint256 value
        ) = abi.decode(_data, (address, uint256));

        // We used to call receiver.transfer(value) but it's no
        // longer considered safe, as it assumes gas costs are
        // immutable, while in fact they are not.
        (bool success, ) = receiver.call{value: value}("");
        require(success, "transfer failed");

        emit EtherWithdrawn(receiver, value);

        return true;
    }
}
