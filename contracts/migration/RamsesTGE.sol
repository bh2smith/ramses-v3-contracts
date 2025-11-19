// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {OAppUpgradeable, Origin, MessagingFee} from "@layerzerolabs/oapp-evm-upgradeable/contracts/oapp/OAppUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IXRam} from "../interfaces/IXRam.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRamsesTGE} from "./interfaces/IRamsesTGE.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/// @title Diamond storage library for RamsesTGE
library RamsesTGEStorage {
    bytes32 internal constant SLOT = keccak256("ramses.tge.storage");

    struct Layout {
        /// @dev paused states
        bool vePaused;
        bool rxpPaused;
        bool hypurrsPaused;
        /// @dev contracts
        IXRam xRam;
        /// @dev timing
        uint256 endTime;
        uint256 globalAirdropped;
        /// @dev mappings
        mapping(address => uint256) veRamClaimable;
        mapping(address => uint256) rxpClaimable;
        mapping(address => uint256) hypurrsClaimable;
        mapping(address => uint256) userAirdroppedTotal;
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = SLOT;
        assembly {
            s.slot := slot
        }
    }
}

/// @title Ramses' x-chain messaging receiver contract, utilizing LayerZero and selected, secure DVN configuration
/// @custom:website https://ramses.xyz
/// @notice Owner controls business logic (pause, populate, etc.) - separate from ProxyAdmin who controls upgrades
contract RamsesTGE is IRamsesTGE, Initializable, OAppUpgradeable, ReentrancyGuardUpgradeable {
    uint256 public constant BASIS = 1_000_000; // denom
    uint256 public constant CONVERSION_RATE = 147_138; // 0.147138 xRAM per veRAM

    /// @dev constants based on the tokenomics @ https://docs.ramses.xyz
    uint256 public constant TOTAL_VE_RAM_AIRDROP = 157_500_000; // 157.5m veRAM
    uint256 public constant TOTAL_RXP_AIRDROP = 10_500_000; // 10.5m xRAM allocated to RXP
    uint256 public constant TOTAL_HYPURRS_AIRDROP = 70_000_000; // 70m xRAM allocated to Hypurrs

    uint256 public constant MAX_AIRDROPPED = TOTAL_VE_RAM_AIRDROP + TOTAL_RXP_AIRDROP + TOTAL_HYPURRS_AIRDROP;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _endpoint) OAppUpgradeable(_endpoint) {
        _disableInitializers();
    }

    /// @notice Initializes the contract
    /// @param _delegate The delegate address for LayerZero operations
    function initialize(address _delegate) public initializer {
        __OApp_init(_delegate);
        __Ownable_init(_delegate);
        __ReentrancyGuard_init();

        RamsesTGEStorage.Layout storage $ = RamsesTGEStorage.layout();
        $.vePaused = true;
        $.rxpPaused = true;
        $.hypurrsPaused = true;
    }

    /// @dev Getter functions for diamond storage
    function vePaused() public view returns (bool) {
        return RamsesTGEStorage.layout().vePaused;
    }

    function rxpPaused() public view returns (bool) {
        return RamsesTGEStorage.layout().rxpPaused;
    }

    function hypurrsPaused() public view returns (bool) {
        return RamsesTGEStorage.layout().hypurrsPaused;
    }

    function xRam() public view returns (IXRam) {
        return RamsesTGEStorage.layout().xRam;
    }

    function endTime() public view returns (uint256) {
        return RamsesTGEStorage.layout().endTime;
    }

    function globalAirdropped() public view returns (uint256) {
        return RamsesTGEStorage.layout().globalAirdropped;
    }

    function veRamClaimable(address user) public view returns (uint256) {
        return RamsesTGEStorage.layout().veRamClaimable[user];
    }

    function rxpClaimable(address user) public view returns (uint256) {
        return RamsesTGEStorage.layout().rxpClaimable[user];
    }

    function hypurrsClaimable(address user) public view returns (uint256) {
        return RamsesTGEStorage.layout().hypurrsClaimable[user];
    }

    function userAirdroppedTotal(address user) public view returns (uint256) {
        return RamsesTGEStorage.layout().userAirdroppedTotal[user];
    }

    /// @dev checks if the airdrop time is valid or not
    modifier enforceAirdropEnd() {
        RamsesTGEStorage.Layout storage $ = RamsesTGEStorage.layout();
        require(block.timestamp < $.endTime, "Airdrop period ended");
        _;
    }

    /// @inheritdoc IRamsesTGE
    /// @dev we do not inherently check for the end of the airdrop for ve claims due to them having to have interacted on Arbitrum prior
    function claimVe(OperationType _operationType) external nonReentrant {
        RamsesTGEStorage.Layout storage $ = RamsesTGEStorage.layout();
        require(!$.vePaused, "paused");
        /// @dev grab claimable from mapping
        uint256 claimableAmount = $.veRamClaimable[msg.sender];
        /// @dev ensure there's a balance
        require(claimableAmount != 0, "no allocation");

        /// @dev ensure the contract has enough xRam
        require($.xRam.balanceOf(address(this)) >= claimableAmount, "contract needs refilling");
        /// @dev zero out the user's claimable balance
        $.veRamClaimable[msg.sender] = 0;
        $.userAirdroppedTotal[msg.sender] += claimableAmount;
        _prepareTransfer(_operationType, claimableAmount);
        /// @dev update the global airdropped amount
        $.globalAirdropped += claimableAmount;
    }

    /// @inheritdoc IRamsesTGE
    function claimRXP(OperationType _operationType) external nonReentrant enforceAirdropEnd {
        RamsesTGEStorage.Layout storage $ = RamsesTGEStorage.layout();
        require(!$.rxpPaused, "paused");
        uint256 claimableAmount = $.rxpClaimable[msg.sender];
        require(claimableAmount != 0, "no allocation");
        require($.xRam.balanceOf(address(this)) >= claimableAmount, "contract needs refilling");
        $.rxpClaimable[msg.sender] = 0;
        $.userAirdroppedTotal[msg.sender] += claimableAmount;
        _prepareTransfer(_operationType, claimableAmount);
        /// @dev update the global airdropped amount
        $.globalAirdropped += claimableAmount;
    }
    
    /// @inheritdoc IRamsesTGE
    function claimHypurrs(OperationType _operationType) external nonReentrant enforceAirdropEnd {
        RamsesTGEStorage.Layout storage $ = RamsesTGEStorage.layout();
        require(!$.hypurrsPaused, "paused");
        uint256 claimableAmount = $.hypurrsClaimable[msg.sender];
        require(claimableAmount != 0, "no allocation");
        require($.xRam.balanceOf(address(this)) >= claimableAmount, "contract needs refilling");
        $.hypurrsClaimable[msg.sender] = 0;
        $.userAirdroppedTotal[msg.sender] += claimableAmount;
        _prepareTransfer(_operationType, claimableAmount);
        /// @dev update the global airdropped amount
        $.globalAirdropped += claimableAmount;
    }

    //// *** ADMIN funcs ***

    /// @inheritdoc IRamsesTGE
    function rescueAll() external onlyOwner {
        RamsesTGEStorage.Layout storage $ = RamsesTGEStorage.layout();
        $.xRam.transfer(owner(), $.xRam.balanceOf(address(this)));
    }

    function rescue(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    /// @inheritdoc IRamsesTGE
    function setXRam(address _xRam) external onlyOwner {
        RamsesTGEStorage.Layout storage $ = RamsesTGEStorage.layout();
        require(address($.xRam) == address(0), "already initialized");
        $.xRam = IXRam(_xRam);
    }

    function setEndTime(uint256 _newEndTimestamp) external onlyOwner {
        RamsesTGEStorage.Layout storage $ = RamsesTGEStorage.layout();
        $.endTime = _newEndTimestamp;
    }

    /// @dev pausing
    function pauseVe(bool _paused) external onlyOwner {
        RamsesTGEStorage.Layout storage $ = RamsesTGEStorage.layout();
        $.vePaused = _paused;
    }

    function pauseRXP(bool _paused) external onlyOwner {
        RamsesTGEStorage.Layout storage $ = RamsesTGEStorage.layout();
        $.rxpPaused = _paused;
    }

    function pauseHypurrs(bool _paused) external onlyOwner {
        RamsesTGEStorage.Layout storage $ = RamsesTGEStorage.layout();
        $.hypurrsPaused = _paused;
    }

    /// @dev populating

    /// @inheritdoc IRamsesTGE
    function populateRXP(address[] memory _users, uint256[] memory _amounts) external onlyOwner {
        RamsesTGEStorage.Layout storage $ = RamsesTGEStorage.layout();
        require(_users.length == _amounts.length, "length mismatch");
        for (uint256 i = 0; i < _users.length; i++) {
            $.rxpClaimable[_users[i]] = _amounts[i];
        }
    }
    /// @inheritdoc IRamsesTGE

    function populateHypurrs(address[] memory _users, uint256[] memory _amounts) external onlyOwner {
        RamsesTGEStorage.Layout storage $ = RamsesTGEStorage.layout();
        require(_users.length == _amounts.length, "length mismatch");
        for (uint256 i = 0; i < _users.length; i++) {
            $.hypurrsClaimable[_users[i]] = _amounts[i];
        }
    }

    //// *** LAYERZERO  && Internal funcs ***

    /**
     * @dev Called when data is received from the protocol. It overrides the equivalent function in the parent contract.
     * Protocol messages are defined as packets, comprised of the following parameters.
     * @param _origin A struct containing information about where the packet came from.
     * @param _guid A global unique identifier for tracking the packet.
     * @param payload Encoded message.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata payload,
        address, // Executor address as specified by the OApp.
        bytes calldata // Any extra data or options to trigger on receipt.
    ) internal override {
        RamsesTGEStorage.Layout storage $ = RamsesTGEStorage.layout();
        /// @dev decode the payload to get the message
        LocalParameters memory data = abi.decode(payload, (LocalParameters));

        /// @dev sanity check for message being decoded
        if (data.amountAirdropped > 0 && data.user != address(0)) {
            /// @dev convert the veRAM bridged amount to xRAM
            uint256 convertedAmount = (data.amountAirdropped * CONVERSION_RATE) / BASIS;
            /// @dev add to the airdrop mapping
            $.veRamClaimable[data.user] += convertedAmount;
            return;
        } else {
            /// @dev terminate or handle no-op
            return;
        }
    }

    /// @dev internal function to send the airdrop to the user
    function _prepareTransfer(OperationType operationType, uint256 _amount) internal {
        RamsesTGEStorage.Layout storage $ = RamsesTGEStorage.layout();

        if (operationType == OperationType.EXIT) {
            // Exit xRAM and receive underlying RAM
            IERC20($.xRam.RAM()).transfer(msg.sender, $.xRam.exit(_amount));
        } else if (operationType == OperationType.CLAIM_XRAM) {
            // Claim as xRAM
            $.xRam.transfer(msg.sender, _amount);
        }
    }
}
