// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

library Pair {
    struct Observation {
        uint256 timestamp;
        uint256 reserve0Cumulative;
        uint256 reserve1Cumulative;
    }
}

interface IPair {
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidSpender(address spender);
    error INSUFFICIENT_INPUT_AMOUNT();
    error INSUFFICIENT_LIQUIDITY();
    error INSUFFICIENT_LIQUIDITY_BURNED();
    error INSUFFICIENT_LIQUIDITY_MINTED();
    error INSUFFICIENT_OUTPUT_AMOUNT();
    error INVALID_TRANSFER();
    error K();
    error NOT_AUTHORIZED(address caller);
    error OVERFLOW();
    error ReentrancyGuardReentrantCall();
    error SAFE_TRANSFER_FAILED();
    error SKIM_DISABLED();
    error UNSTABLE_RATIO();

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function MINIMUM_LIQUIDITY() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function current(address tokenIn, uint256 amountIn) external view returns (uint256 amountOut);
    function currentCumulativePrices()
        external
        view
        returns (uint256 reserve0Cumulative, uint256 reserve1Cumulative, uint256 blockTimestamp);
    function decimals() external view returns (uint8);
    function factory() external view returns (address);
    function fee() external view returns (uint256);
    function feeRecipient() external view returns (address);
    function feeSplit() external view returns (uint256);
    function getAmountOut(uint256 amountIn, address tokenIn) external view returns (uint256);
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function initialize(address _token0, address _token1, bool _stable) external;
    function kLast() external view returns (uint256);
    function lastObservation() external view returns (Pair.Observation memory);
    function metadata()
        external
        view
        returns (
            uint256 _decimals0,
            uint256 _decimals1,
            uint256 _reserve0,
            uint256 _reserve1,
            bool _stable,
            address _token0,
            address _token1
        );
    function mint(address to) external returns (uint256 liquidity);
    function mintFee() external;
    function name() external view returns (string memory);
    function observationLength() external view returns (uint256);
    function observations(uint256)
        external
        view
        returns (uint256 timestamp, uint256 reserve0Cumulative, uint256 reserve1Cumulative);
    function prices(address tokenIn, uint256 amountIn, uint256 points) external view returns (uint256[] memory);
    function quote(address tokenIn, uint256 amountIn, uint256 granularity) external view returns (uint256 amountOut);
    function reserve0CumulativeLast() external view returns (uint256);
    function reserve1CumulativeLast() external view returns (uint256);
    function sample(address tokenIn, uint256 amountIn, uint256 points, uint256 window)
        external
        view
        returns (uint256[] memory);
    function setFee(uint256 _fee) external;
    function setFeeRecipient(address _feeRecipient) external;
    function setFeeSplit(uint256 _feeSplit) external;
    function skim(address to) external;
    function stable() external view returns (bool);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes memory data) external;
    function symbol() external view returns (string memory);
    function sync() external;
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
