// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract AMM {
    address public tokenA;
    address public tokenB;
    
    uint256 public reserveA;
    uint256 public reserveB;

    // Events for logging swap activity
    event Swap(address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);
    event AddLiquidity(address indexed user, uint256 amountA, uint256 amountB);
    event RemoveLiquidity(address indexed user, uint256 amountA, uint256 amountB);

    // Constructor to initialize the two tokens for trading
    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    // Function to add liquidity to the AMM pool
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "AMM: Invalid liquidity amounts");
        
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        reserveA += amountA;
        reserveB += amountB;

        emit AddLiquidity(msg.sender, amountA, amountB);
    }

    // Function to remove liquidity from the AMM pool
    function removeLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA <= reserveA && amountB <= reserveB, "AMM: Insufficient liquidity");
        
        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        reserveA -= amountA;
        reserveB -= amountB;

        emit RemoveLiquidity(msg.sender, amountA, amountB);
    }

    // Function to swap tokenA for tokenB
    function swapAtoB(uint256 amountA) external {
        require(amountA > 0, "AMM: Invalid amount");
        uint256 amountB = getAmountOut(amountA, reserveA, reserveB);

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        reserveA += amountA;
        reserveB -= amountB;

        emit Swap(msg.sender, tokenA, tokenB, amountA, amountB);
    }

    // Function to swap tokenB for tokenA
    function swapBtoA(uint256 amountB) external {
        require(amountB > 0, "AMM: Invalid amount");
        uint256 amountA = getAmountOut(amountB, reserveB, reserveA);

        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);
        IERC20(tokenA).transfer(msg.sender, amountA);

        reserveB += amountB;
        reserveA -= amountA;

        emit Swap(msg.sender, tokenB, tokenA, amountB, amountA);
    }

    // Private helper function to calculate the output amount of a swap
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) private pure returns (uint256) {
        require(amountIn > 0, "AMM: Invalid amount");
        uint256 numerator = amountIn * reserveOut;
        uint256 denominator = reserveIn + amountIn;
        return numerator / denominator;
    }
}

